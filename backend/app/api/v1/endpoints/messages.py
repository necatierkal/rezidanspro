import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, verify_community_membership
from app.models.all_models import User, PrivateMessage, CommunityMember, Notification, AuditLog
from app.schemas.all_schemas import MessageCreate, MessageOut

router = APIRouter(prefix="/messages", tags=["Private Messages (Manager <-> Resident Only)"])

@router.get("", response_model=List[MessageOut])
def get_user_messages(
    community_id: int = Query(...),
    contact_user_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Returns strictly messages where the current user is either the SENDER or the RECEIVER.
    Zero leakage to other residents."""
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    query = db.query(PrivateMessage).filter(
        PrivateMessage.community_id == community_id,
        or_(
            PrivateMessage.sender_id == current_user.id,
            PrivateMessage.receiver_id == current_user.id
        )
    )

    if contact_user_id:
        query = query.filter(
            or_(
                and_(PrivateMessage.sender_id == current_user.id, PrivateMessage.receiver_id == contact_user_id),
                and_(PrivateMessage.sender_id == contact_user_id, PrivateMessage.receiver_id == current_user.id)
            )
        )

    messages = query.order_by(PrivateMessage.created_at.desc()).all()

    results = []
    for m in messages:
        sender_name = f"{m.sender.first_name} {m.sender.last_name}" if m.sender else ""
        receiver_name = f"{m.receiver.first_name} {m.receiver.last_name}" if m.receiver else ""
        results.append(
            MessageOut(
                id=m.id,
                community_id=m.community_id,
                sender_id=m.sender_id,
                sender_name=sender_name,
                receiver_id=m.receiver_id,
                receiver_name=receiver_name,
                subject=m.subject,
                body=m.body,
                created_at=m.created_at,
                read_at=m.read_at
            )
        )
    return results

@router.post("", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def send_private_message(
    data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Enforces Manager <-> Resident communication only (Sec 25: NO SAKIN -> SAKIN).
    Either sender or receiver MUST be a manager/assistant_manager of the community."""
    verify_community_membership(community_id=data.community_id, current_user=current_user, db=db)

    # Check sender role
    sender_mem = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.user_id == current_user.id
    ).first()
    sender_is_manager = sender_mem and sender_mem.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    # Check receiver role and membership
    receiver_mem = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.user_id == data.receiver_id
    ).first()
    if not receiver_mem:
        raise HTTPException(status_code=400, detail="Alıcı bu sitenin üyesi değil.")

    receiver_is_manager = receiver_mem.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    # Section 25 Rule: Sakin -> Sakin messaging is NOT ALLOWED to prevent social media noise
    if not sender_is_manager and not receiver_is_manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Özel mesajlaşma yalnızca yönetici ve sakin arasında yapılabilir. Sakinler arası mesajlaşma kapalıdır."
        )

    msg = PrivateMessage(
        community_id=data.community_id,
        sender_id=current_user.id,
        receiver_id=data.receiver_id,
        subject=data.subject,
        body=data.body
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    # Notify receiver
    notif = Notification(
        user_id=data.receiver_id,
        type="PRIVATE_MESSAGE",
        title=f"Yeni Özel Mesaj: {current_user.first_name} {current_user.last_name}",
        body="Yeni bir özel mesajınız var. Okumak için uygulamaya giriş yapınız."
    )
    db.add(notif)
    db.commit()

    return MessageOut(
        id=msg.id,
        community_id=msg.community_id,
        sender_id=msg.sender_id,
        sender_name=f"{current_user.first_name} {current_user.last_name}",
        receiver_id=msg.receiver_id,
        receiver_name=f"{receiver_mem.user.first_name} {receiver_mem.user.last_name}",
        subject=msg.subject,
        body=msg.body,
        created_at=msg.created_at,
        read_at=None
    )

@router.get("/{id}", response_model=MessageOut)
def get_message_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """OWNERSHIP CHECK (Sec 26):
    A user changing message_id in URL cannot access another user's message.
    if message.receiver_id != current_user.id and message.sender_id != current_user.id: 403 Forbidden."""
    msg = db.query(PrivateMessage).filter(PrivateMessage.id == id).first()
    if not msg:
        raise HTTPException(status_code=404, detail="Mesaj bulunamadı.")

    if msg.receiver_id != current_user.id and msg.sender_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu mesaja erişim yetkiniz bulunmamaktadır."
        )

    # If receiver is opening it, mark read
    if msg.receiver_id == current_user.id and msg.read_at is None:
        msg.read_at = datetime.datetime.now(datetime.timezone.utc)
        db.commit()

    sender_name = f"{msg.sender.first_name} {msg.sender.last_name}" if msg.sender else ""
    receiver_name = f"{msg.receiver.first_name} {msg.receiver.last_name}" if msg.receiver else ""

    return MessageOut(
        id=msg.id,
        community_id=msg.community_id,
        sender_id=msg.sender_id,
        sender_name=sender_name,
        receiver_id=msg.receiver_id,
        receiver_name=receiver_name,
        subject=msg.subject,
        body=msg.body,
        created_at=msg.created_at,
        read_at=msg.read_at
    )

@router.put("/{id}/read")
def mark_message_as_read(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    msg = db.query(PrivateMessage).filter(PrivateMessage.id == id).first()
    if not msg:
        raise HTTPException(status_code=404, detail="Mesaj bulunamadı.")

    if msg.receiver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Yalnızca alıcı mesajı okundu olarak işaretleyebilir.")

    msg.read_at = datetime.datetime.now(datetime.timezone.utc)
    db.commit()
    return {"message": "Mesaj okundu olarak işaretlendi."}
