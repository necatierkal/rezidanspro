import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, require_manager_role, verify_community_membership
from app.models.all_models import (
    User, MaintenanceRequest, MaintenanceComment, CommunityMember, Notification, AuditLog
)
from app.schemas.all_schemas import (
    MaintenanceCreate, MaintenanceUpdate, MaintenanceOut,
    MaintenanceCommentCreate, MaintenanceCommentOut
)

router = APIRouter(prefix="/maintenance", tags=["Maintenance"])

@router.get("", response_model=List[MaintenanceOut])
def list_maintenance_requests(
    community_id: int = Query(...),
    status_filter: Optional[str] = None,
    category_filter: Optional[str] = None,
    mine_only: Optional[bool] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    cm = verify_community_membership(community_id=community_id, current_user=current_user, db=db)
    is_manager = cm.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    query = db.query(MaintenanceRequest).filter(MaintenanceRequest.community_id == community_id)

    # Privacy enforcement (Sec 18):
    # If not manager, resident CAN ONLY SEE THEIR OWN reported requests!
    if not is_manager or mine_only:
        query = query.filter(MaintenanceRequest.reported_by == current_user.id)

    if status_filter:
        query = query.filter(MaintenanceRequest.status == status_filter.upper())
    if category_filter:
        query = query.filter(MaintenanceRequest.category == category_filter.upper())

    requests = query.order_by(MaintenanceRequest.created_at.desc()).all()

    results = []
    for r in requests:
        comments_out = [
            MaintenanceCommentOut(
                id=c.id,
                request_id=c.request_id,
                author_id=c.author_id,
                author_name=f"{c.author.first_name} {c.author.last_name}" if c.author else "Sistem",
                body=c.body,
                created_at=c.created_at
            ) for c in r.comments
        ]
        reporter_name = f"{r.reporter.first_name} {r.reporter.last_name}" if r.reporter else ""
        results.append(
            MaintenanceOut(
                id=r.id,
                community_id=r.community_id,
                apartment_id=r.apartment_id,
                reported_by=r.reported_by,
                reporter_name=reporter_name,
                category=r.category,
                title=r.title,
                description=r.description,
                status=r.status,
                priority=r.priority,
                photo_url=r.photo_url,
                created_at=r.created_at,
                resolved_at=r.resolved_at,
                comments=comments_out
            )
        )
    return results

@router.post("", response_model=MaintenanceOut, status_code=status.HTTP_201_CREATED)
def create_maintenance_request(
    data: MaintenanceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    verify_community_membership(community_id=data.community_id, current_user=current_user, db=db)

    req = MaintenanceRequest(
        community_id=data.community_id,
        apartment_id=data.apartment_id,
        reported_by=current_user.id,
        category=data.category.upper(),
        title=data.title,
        description=data.description,
        status="OPEN",
        priority=data.priority.upper(),
        photo_url=data.photo_url
    )
    db.add(req)
    db.commit()
    db.refresh(req)

    # Notify managers of new maintenance request
    managers = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.role.in_(["MANAGER", "ASSISTANT_MANAGER"]),
        CommunityMember.status == "ACTIVE"
    ).all()

    for m in managers:
        notif = Notification(
            user_id=m.user_id,
            type="MAINTENANCE",
            title=f"Yeni Arıza Bildirimi: {req.title}",
            body=f"{current_user.first_name} {current_user.last_name} yeni bir arıza bildirdi."
        )
        db.add(notif)
    db.commit()

    return MaintenanceOut(
        id=req.id,
        community_id=req.community_id,
        apartment_id=req.apartment_id,
        reported_by=req.reported_by,
        reporter_name=f"{current_user.first_name} {current_user.last_name}",
        category=req.category,
        title=req.title,
        description=req.description,
        status=req.status,
        priority=req.priority,
        photo_url=req.photo_url,
        created_at=req.created_at,
        resolved_at=None,
        comments=[]
    )

@router.get("/{id}", response_model=MaintenanceOut)
def get_maintenance_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Arıza kaydı bulunamadı.")

    cm = verify_community_membership(community_id=req.community_id, current_user=current_user, db=db)
    is_manager = cm.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    # Privacy check: Resident can only view their own ticket
    if not is_manager and req.reported_by != current_user.id:
        raise HTTPException(status_code=403, detail="Bu arıza kaydını görüntüleme yetkiniz yok.")

    comments_out = [
        MaintenanceCommentOut(
            id=c.id,
            request_id=c.request_id,
            author_id=c.author_id,
            author_name=f"{c.author.first_name} {c.author.last_name}" if c.author else "Sistem",
            body=c.body,
            created_at=c.created_at
        ) for c in req.comments
    ]

    return MaintenanceOut(
        id=req.id,
        community_id=req.community_id,
        apartment_id=req.apartment_id,
        reported_by=req.reported_by,
        reporter_name=f"{req.reporter.first_name} {req.reporter.last_name}" if req.reporter else "",
        category=req.category,
        title=req.title,
        description=req.description,
        status=req.status,
        priority=req.priority,
        photo_url=req.photo_url,
        created_at=req.created_at,
        resolved_at=req.resolved_at,
        comments=comments_out
    )

@router.put("/{id}", response_model=MaintenanceOut)
def update_maintenance_status(
    id: int,
    data: MaintenanceUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Arıza kaydı bulunamadı.")

    require_manager_role(community_id=req.community_id, current_user=current_user, db=db)

    old_status = req.status
    if data.status:
        req.status = data.status.upper()
        if req.status == "RESOLVED":
            req.resolved_at = datetime.datetime.now(datetime.timezone.utc)
    if data.priority:
        req.priority = data.priority.upper()

    db.commit()
    db.refresh(req)

    # Notify reporter if status changed
    if data.status and data.status.upper() != old_status:
        status_tr = {
            "OPEN": "Açık",
            "IN_PROGRESS": "İşlemde",
            "WAITING": "Beklemede",
            "RESOLVED": "Çözüldü",
            "CLOSED": "Kapandı"
        }.get(req.status, req.status)
        
        notif = Notification(
            user_id=req.reported_by,
            type="MAINTENANCE",
            title=f"Arıza Durumu Güncellendi: {req.title}",
            body=f"Arıza kaydınızın durumu '{status_tr}' olarak güncellendi."
        )
        db.add(notif)
        db.commit()

    comments_out = [
        MaintenanceCommentOut(
            id=c.id,
            request_id=c.request_id,
            author_id=c.author_id,
            author_name=f"{c.author.first_name} {c.author.last_name}" if c.author else "Sistem",
            body=c.body,
            created_at=c.created_at
        ) for c in req.comments
    ]

    return MaintenanceOut(
        id=req.id,
        community_id=req.community_id,
        apartment_id=req.apartment_id,
        reported_by=req.reported_by,
        reporter_name=f"{req.reporter.first_name} {req.reporter.last_name}" if req.reporter else "",
        category=req.category,
        title=req.title,
        description=req.description,
        status=req.status,
        priority=req.priority,
        photo_url=req.photo_url,
        created_at=req.created_at,
        resolved_at=req.resolved_at,
        comments=comments_out
    )

@router.post("/{id}/comments", response_model=MaintenanceCommentOut)
def add_maintenance_comment(
    id: int,
    data: MaintenanceCommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Arıza kaydı bulunamadı.")

    cm = verify_community_membership(community_id=req.community_id, current_user=current_user, db=db)
    is_manager = cm.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    # Must be manager or the reporter
    if not is_manager and req.reported_by != current_user.id:
        raise HTTPException(status_code=403, detail="Yorum ekleme yetkiniz yok.")

    comment = MaintenanceComment(
        request_id=req.id,
        author_id=current_user.id,
        body=data.body
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    return MaintenanceCommentOut(
        id=comment.id,
        request_id=comment.request_id,
        author_id=comment.author_id,
        author_name=f"{current_user.first_name} {current_user.last_name}",
        body=comment.body,
        created_at=comment.created_at
    )
