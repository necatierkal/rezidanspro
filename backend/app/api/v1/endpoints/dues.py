import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import (
    get_current_user, require_manager_role, verify_community_membership, get_user_apartments
)
from app.models.all_models import (
    User, Due, DuePayment, Apartment, Block, ApartmentMember, CommunityMember, Notification, AuditLog
)
from app.schemas.all_schemas import DueCreate, DueOut, DuePaymentCreate, DuePaymentOut

router = APIRouter(prefix="/dues", tags=["Dues & Aidat (Strict Privacy)"])

@router.get("/my", response_model=List[DueOut])
def get_my_dues(
    community_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """RESIDENT SECURE ENDPOINT: Returns strictly the dues belonging to current_user's apartments in this community.
    Never exposes any other resident's debt, amount, or apartment number."""
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    # Get user's apartments in this community
    apt_ids = db.query(ApartmentMember.apartment_id).join(Apartment).join(Block).filter(
        ApartmentMember.user_id == current_user.id,
        Block.community_id == community_id
    ).all()
    apartment_ids = [a[0] for a in apt_ids]

    if not apartment_ids:
        return []

    dues = db.query(Due).filter(
        Due.community_id == community_id,
        Due.apartment_id.in_(apartment_ids)
    ).order_by(Due.due_date.desc()).all()

    results = []
    for d in dues:
        apt = d.apartment
        block_name = apt.block.name if apt and apt.block else ""
        payments_out = [
            DuePaymentOut(
                id=p.id,
                due_id=p.due_id,
                amount=p.amount,
                paid_at=p.paid_at,
                payment_method=p.payment_method,
                reference=p.reference
            ) for p in d.payments
        ]
        results.append(
            DueOut(
                id=d.id,
                community_id=d.community_id,
                apartment_id=d.apartment_id,
                block_name=block_name,
                apartment_no=apt.apartment_no if apt else "",
                period=d.period,
                amount=d.amount,
                due_date=d.due_date,
                status=d.status,
                notes=d.notes,
                created_at=d.created_at,
                payments=payments_out
            )
        )
    return results

@router.get("/manager", response_model=List[DueOut])
def get_manager_dues(
    community_id: int = Query(...),
    status_filter: Optional[str] = None,
    period_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """MANAGER-ONLY ENDPOINT: Strict authorization check.
    If called by a resident without manager role, raises 403 Forbidden."""
    require_manager_role(community_id=community_id, current_user=current_user, db=db)

    query = db.query(Due).filter(Due.community_id == community_id)
    if status_filter:
        query = query.filter(Due.status == status_filter.upper())
    if period_filter:
        query = query.filter(Due.period == period_filter)

    dues = query.order_by(Due.due_date.desc()).all()

    results = []
    for d in dues:
        apt = d.apartment
        block_name = apt.block.name if apt and apt.block else ""
        payments_out = [
            DuePaymentOut(
                id=p.id,
                due_id=p.due_id,
                amount=p.amount,
                paid_at=p.paid_at,
                payment_method=p.payment_method,
                reference=p.reference
            ) for p in d.payments
        ]
        results.append(
            DueOut(
                id=d.id,
                community_id=d.community_id,
                apartment_id=d.apartment_id,
                block_name=block_name,
                apartment_no=apt.apartment_no if apt else "",
                period=d.period,
                amount=d.amount,
                due_date=d.due_date,
                status=d.status,
                notes=d.notes,
                created_at=d.created_at,
                payments=payments_out
            )
        )
    return results

@router.post("", response_model=DueOut, status_code=status.HTTP_201_CREATED)
def create_due(
    data: DueCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """MANAGER-ONLY ENDPOINT: Defines due for an apartment.
    Sends a privacy-safe notification to the resident without exposing debt amounts on lock screen."""
    require_manager_role(community_id=data.community_id, current_user=current_user, db=db)

    # Verify apartment belongs to community
    apt = db.query(Apartment).join(Block).filter(
        Apartment.id == data.apartment_id,
        Block.community_id == data.community_id
    ).first()
    if not apt:
        raise HTTPException(status_code=400, detail="Belirtilen daire bu siteye ait değil.")

    due = Due(
        community_id=data.community_id,
        apartment_id=data.apartment_id,
        period=data.period,
        amount=data.amount,
        due_date=data.due_date,
        status="UNPAID",
        notes=data.notes
    )
    db.add(due)
    db.commit()
    db.refresh(due)

    # Send privacy-safe notification to apartment residents (Sec 10 & 27 & 53)
    # Notice: NO AMOUNT IN NOTIFICATION BODY!
    residents = db.query(ApartmentMember).filter(ApartmentMember.apartment_id == apt.id).all()
    for res in residents:
        notif = Notification(
            user_id=res.user_id,
            type="DUES_REMINDER",
            title="Aidat Bilgilendirmesi",
            body="Yeni bir aidat tahakkuk etmiştir. Detayları uygulamaya giriş yaparak güvenle inceleyebilirsiniz."
        )
        db.add(notif)

    # Audit log (Sec 67 & 68: manager action logged without sensitive personal debt text)
    audit = AuditLog(
        actor_user_id=current_user.id,
        community_id=data.community_id,
        action="MANAGER_CREATED_DUE",
        entity_type="DUE",
        entity_id=due.id
    )
    db.add(audit)
    db.commit()

    return DueOut(
        id=due.id,
        community_id=due.community_id,
        apartment_id=due.apartment_id,
        block_name=apt.block.name,
        apartment_no=apt.apartment_no,
        period=due.period,
        amount=due.amount,
        due_date=due.due_date,
        status=due.status,
        notes=due.notes,
        created_at=due.created_at,
        payments=[]
    )

@router.get("/{id}", response_model=DueOut)
def get_due_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """OWNERSHIP & PRIVACY CHECK:
    Only the resident living in this apartment OR the community manager can view this due record.
    Any other resident receives 403 Forbidden."""
    due = db.query(Due).filter(Due.id == id).first()
    if not due:
        raise HTTPException(status_code=404, detail="Aidat kaydı bulunamadı.")

    # Check manager role
    cm = db.query(CommunityMember).filter(
        CommunityMember.community_id == due.community_id,
        CommunityMember.user_id == current_user.id,
        CommunityMember.status == "ACTIVE"
    ).first()

    is_manager = cm and cm.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    # Check resident ownership
    is_resident_owner = False
    if not is_manager:
        user_apts = get_user_apartments(current_user.id, db)
        is_resident_owner = due.apartment_id in user_apts

    if not is_manager and not is_resident_owner:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu aidat kaydını görüntüleme yetkiniz bulunmamaktadır."
        )

    apt = due.apartment
    block_name = apt.block.name if apt and apt.block else ""
    payments_out = [
        DuePaymentOut(
            id=p.id,
            due_id=p.due_id,
            amount=p.amount,
            paid_at=p.paid_at,
            payment_method=p.payment_method,
            reference=p.reference
        ) for p in due.payments
    ]

    return DueOut(
        id=due.id,
        community_id=due.community_id,
        apartment_id=due.apartment_id,
        block_name=block_name,
        apartment_no=apt.apartment_no if apt else "",
        period=due.period,
        amount=due.amount,
        due_date=due.due_date,
        status=due.status,
        notes=due.notes,
        created_at=due.created_at,
        payments=payments_out
    )

@router.post("/{id}/payments", response_model=DueOut)
def record_due_payment(
    id: int,
    data: DuePaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """MANAGER-ONLY ENDPOINT (Sec 56):
    Residents cannot unilaterally mark their dues as paid. Only the manager can record payment."""
    due = db.query(Due).filter(Due.id == id).first()
    if not due:
        raise HTTPException(status_code=404, detail="Aidat kaydı bulunamadı.")

    require_manager_role(community_id=due.community_id, current_user=current_user, db=db)

    payment = DuePayment(
        due_id=due.id,
        amount=data.amount,
        payment_method=data.payment_method.upper(),
        reference=data.reference
    )
    db.add(payment)

    # Check total payments
    total_paid = sum(p.amount for p in due.payments) + data.amount
    if total_paid >= due.amount:
        due.status = "PAID"
    elif total_paid > 0:
        due.status = "PARTIAL"

    # Audit log
    audit = AuditLog(
        actor_user_id=current_user.id,
        community_id=due.community_id,
        action="MANAGER_RECORDED_PAYMENT",
        entity_type="DUE",
        entity_id=due.id
    )
    db.add(audit)
    db.commit()
    db.refresh(due)

    # Notify resident of payment recording
    residents = db.query(ApartmentMember).filter(ApartmentMember.apartment_id == due.apartment_id).all()
    for res in residents:
        notif = Notification(
            user_id=res.user_id,
            type="DUES_REMINDER",
            title="Aidat Ödeme Bilgisi",
            body=f"{due.period} dönemi aidat ödemeniz onaylandı."
        )
        db.add(notif)
    db.commit()

    apt = due.apartment
    block_name = apt.block.name if apt and apt.block else ""
    payments_out = [
        DuePaymentOut(
            id=p.id,
            due_id=p.due_id,
            amount=p.amount,
            paid_at=p.paid_at,
            payment_method=p.payment_method,
            reference=p.reference
        ) for p in due.payments
    ]

    return DueOut(
        id=due.id,
        community_id=due.community_id,
        apartment_id=due.apartment_id,
        block_name=block_name,
        apartment_no=apt.apartment_no if apt else "",
        period=due.period,
        amount=due.amount,
        due_date=due.due_date,
        status=due.status,
        notes=due.notes,
        created_at=due.created_at,
        payments=payments_out
    )
