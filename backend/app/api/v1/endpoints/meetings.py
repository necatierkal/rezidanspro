from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, require_manager_role, verify_community_membership
from app.models.all_models import User, Meeting, MeetingAttendee, CommunityMember, Notification, AuditLog
from app.schemas.all_schemas import MeetingCreate, MeetingOut, MeetingRSVPRequest

router = APIRouter(prefix="/meetings", tags=["Meetings"])

@router.get("", response_model=List[MeetingOut])
def list_meetings(
    community_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    meetings = db.query(Meeting).filter(Meeting.community_id == community_id).order_by(Meeting.start_at.asc()).all()
    results = []
    for m in meetings:
        attending_count = db.query(MeetingAttendee).filter(
            MeetingAttendee.meeting_id == m.id,
            MeetingAttendee.status == "ATTENDING"
        ).count()

        user_rsvp = None
        user_att = db.query(MeetingAttendee).filter(
            MeetingAttendee.meeting_id == m.id,
            MeetingAttendee.user_id == current_user.id
        ).first()
        if user_att:
            user_rsvp = user_att.status

        results.append(
            MeetingOut(
                id=m.id,
                community_id=m.community_id,
                title=m.title,
                description=m.description,
                location=m.location,
                start_at=m.start_at,
                end_at=m.end_at,
                created_by=m.created_by,
                created_at=m.created_at,
                attending_count=attending_count,
                user_rsvp=user_rsvp
            )
        )
    return results

@router.post("", response_model=MeetingOut, status_code=status.HTTP_201_CREATED)
def create_meeting(
    data: MeetingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager_role(community_id=data.community_id, current_user=current_user, db=db)

    meeting = Meeting(
        community_id=data.community_id,
        title=data.title,
        description=data.description,
        location=data.location,
        start_at=data.start_at,
        end_at=data.end_at,
        created_by=current_user.id
    )
    db.add(meeting)
    db.commit()
    db.refresh(meeting)

    # Notify members
    members = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.status == "ACTIVE"
    ).all()

    for mem in members:
        if mem.user_id != current_user.id:
            notif = Notification(
                user_id=mem.user_id,
                type="MEETING",
                title=f"Yeni Toplantı: {meeting.title}",
                body=f"Tarih: {meeting.start_at.strftime('%d.%m.%Y %H:%M')} - Konum: {meeting.location}"
            )
            db.add(notif)
    db.commit()

    return MeetingOut(
        id=meeting.id,
        community_id=meeting.community_id,
        title=meeting.title,
        description=meeting.description,
        location=meeting.location,
        start_at=meeting.start_at,
        end_at=meeting.end_at,
        created_by=meeting.created_by,
        created_at=meeting.created_at,
        attending_count=0,
        user_rsvp=None
    )

@router.post("/{id}/rsvp")
def rsvp_meeting(
    id: int,
    data: MeetingRSVPRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    meeting = db.query(Meeting).filter(Meeting.id == id).first()
    if not meeting:
        raise HTTPException(status_code=404, detail="Toplantı bulunamadı.")

    verify_community_membership(community_id=meeting.community_id, current_user=current_user, db=db)

    existing = db.query(MeetingAttendee).filter(
        MeetingAttendee.meeting_id == meeting.id,
        MeetingAttendee.user_id == current_user.id
    ).first()

    status_val = data.status.upper()
    if status_val not in ["ATTENDING", "NOT_ATTENDING", "TENTATIVE"]:
        status_val = "ATTENDING"

    if existing:
        existing.status = status_val
    else:
        new_rsvp = MeetingAttendee(
            meeting_id=meeting.id,
            user_id=current_user.id,
            status=status_val
        )
        db.add(new_rsvp)

    db.commit()
    return {"message": "Katılım durumunuz güncellendi.", "status": status_val}
