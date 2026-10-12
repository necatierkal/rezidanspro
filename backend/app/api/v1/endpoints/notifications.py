from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user
from app.models.all_models import User, Notification, Device
from app.schemas.all_schemas import NotificationOut, DeviceRegister

router = APIRouter(prefix="/notifications", tags=["Notifications & Devices"])

@router.get("", response_model=List[NotificationOut])
def get_user_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notifs = db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).order_by(Notification.created_at.desc()).limit(50).all()
    return notifs

@router.put("/{id}/read")
def mark_notification_read(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notif = db.query(Notification).filter(
        Notification.id == id,
        Notification.user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Bildirim bulunamadı.")
    notif.is_read = True
    db.commit()
    return {"message": "Bildirim okundu olarak işaretlendi."}

@router.put("/read-all")
def mark_all_notifications_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"message": "Tüm bildirimler okundu olarak işaretlendi."}

@router.post("/devices")
def register_device(
    data: DeviceRegister,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    existing = db.query(Device).filter(
        Device.user_id == current_user.id,
        Device.push_token == data.push_token
    ).first()
    if existing:
        existing.platform = data.platform.upper()
    else:
        dev = Device(
            user_id=current_user.id,
            platform=data.platform.upper(),
            push_token=data.push_token
        )
        db.add(dev)
    db.commit()
    return {"message": "Cihaz bildirimi başarıyla kaydedildi."}
