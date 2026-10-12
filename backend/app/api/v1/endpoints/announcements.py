from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, require_manager_role, verify_community_membership
from app.models.all_models import User, Announcement, CommunityMember, Notification, AuditLog
from app.schemas.all_schemas import AnnouncementCreate, AnnouncementUpdate, AnnouncementOut

router = APIRouter(prefix="/announcements", tags=["Announcements"])

@router.get("", response_model=List[AnnouncementOut])
def get_announcements(
    community_id: int = Query(...),
    priority: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Tenant verification
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    query = db.query(Announcement).filter(Announcement.community_id == community_id)
    if priority:
        query = query.filter(Announcement.priority == priority.upper())
    
    announcements = query.order_by(Announcement.published_at.desc()).offset(offset).limit(limit).all()

    results = []
    for a in announcements:
        author_name = "Yönetim"
        if a.author:
            author_name = f"{a.author.first_name} {a.author.last_name}"
        results.append(
            AnnouncementOut(
                id=a.id,
                community_id=a.community_id,
                author_id=a.author_id,
                author_name=author_name,
                title=a.title,
                body=a.body,
                priority=a.priority,
                attachment_url=a.attachment_url,
                published_at=a.published_at,
                expires_at=a.expires_at
            )
        )
    return results

@router.post("", response_model=AnnouncementOut, status_code=status.HTTP_201_CREATED)
def create_announcement(
    data: AnnouncementCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Role verification: Only MANAGER / ASSISTANT_MANAGER can create announcements!
    require_manager_role(community_id=data.community_id, current_user=current_user, db=db)

    announcement = Announcement(
        community_id=data.community_id,
        author_id=current_user.id,
        title=data.title,
        body=data.body,
        priority=data.priority.upper(),
        attachment_url=data.attachment_url,
        expires_at=data.expires_at
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)

    # Broadcast notification to all active residents in community (Sec 15)
    members = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.status == "ACTIVE"
    ).all()

    for m in members:
        if m.user_id != current_user.id:
            notif = Notification(
                user_id=m.user_id,
                type="ANNOUNCEMENT",
                title=f"Yeni Duyuru: {announcement.title}",
                body=announcement.body[:150] + ("..." if len(announcement.body) > 150 else "")
            )
            db.add(notif)

    # Audit log
    audit = AuditLog(
        actor_user_id=current_user.id,
        community_id=data.community_id,
        action="CREATED_ANNOUNCEMENT",
        entity_type="ANNOUNCEMENT",
        entity_id=announcement.id
    )
    db.add(audit)
    db.commit()

    return AnnouncementOut(
        id=announcement.id,
        community_id=announcement.community_id,
        author_id=announcement.author_id,
        author_name=f"{current_user.first_name} {current_user.last_name}",
        title=announcement.title,
        body=announcement.body,
        priority=announcement.priority,
        attachment_url=announcement.attachment_url,
        published_at=announcement.published_at,
        expires_at=announcement.expires_at
    )

@router.put("/{id}", response_model=AnnouncementOut)
def update_announcement(
    id: int,
    data: AnnouncementUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    announcement = db.query(Announcement).filter(Announcement.id == id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Duyuru bulunamadı.")

    require_manager_role(community_id=announcement.community_id, current_user=current_user, db=db)

    if data.title is not None:
        announcement.title = data.title
    if data.body is not None:
        announcement.body = data.body
    if data.priority is not None:
        announcement.priority = data.priority.upper()
    if data.attachment_url is not None:
        announcement.attachment_url = data.attachment_url
    if data.expires_at is not None:
        announcement.expires_at = data.expires_at

    db.commit()
    db.refresh(announcement)
    return AnnouncementOut(
        id=announcement.id,
        community_id=announcement.community_id,
        author_id=announcement.author_id,
        author_name=f"{current_user.first_name} {current_user.last_name}",
        title=announcement.title,
        body=announcement.body,
        priority=announcement.priority,
        attachment_url=announcement.attachment_url,
        published_at=announcement.published_at,
        expires_at=announcement.expires_at
    )

@router.delete("/{id}")
def delete_announcement(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    announcement = db.query(Announcement).filter(Announcement.id == id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Duyuru bulunamadı.")

    require_manager_role(community_id=announcement.community_id, current_user=current_user, db=db)

    db.delete(announcement)
    db.commit()
    return {"message": "Duyuru başarıyla silindi."}
