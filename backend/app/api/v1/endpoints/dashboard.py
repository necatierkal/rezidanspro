from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import (
    get_current_user, require_manager_role, verify_community_membership, get_user_apartments
)
from app.models.all_models import (
    User, Community, CommunityMember, Block, Apartment, ApartmentMember,
    Announcement, MaintenanceRequest, Meeting, Poll, Due, DuePayment
)
from app.schemas.all_schemas import (
    ManagerDashboardStats, ResidentDashboardSummary, AnnouncementOut, MeetingOut, PollOut, PollOptionOut
)

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/manager", response_model=ManagerDashboardStats)
def get_manager_dashboard(
    community_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """MANAGER DASHBOARD STATS (Sec 11, 12):
    Forbidden for residents. Returns aggregate overview."""
    require_manager_role(community_id=community_id, current_user=current_user, db=db)

    # Total apartments
    total_apartments = db.query(Apartment).join(Block).filter(Block.community_id == community_id).count()

    # Active residents
    active_residents = db.query(CommunityMember).filter(
        CommunityMember.community_id == community_id,
        CommunityMember.status == "ACTIVE"
    ).count()

    # Open faults
    open_faults = db.query(MaintenanceRequest).filter(
        MaintenanceRequest.community_id == community_id,
        MaintenanceRequest.status.in_(["OPEN", "IN_PROGRESS"])
    ).count()

    # Pending requests
    pending_requests = db.query(MaintenanceRequest).filter(
        MaintenanceRequest.community_id == community_id,
        MaintenanceRequest.status == "WAITING"
    ).count()

    # Dues metrics
    all_dues = db.query(Due).filter(Due.community_id == community_id).all()
    total_amount = sum(d.amount for d in all_dues)
    
    # Payments
    total_collected = 0.0
    for d in all_dues:
        for p in d.payments:
            total_collected += p.amount

    total_unpaid = max(0.0, total_amount - total_collected)
    collection_rate = (total_collected / total_amount * 100) if total_amount > 0 else 100.0

    return ManagerDashboardStats(
        total_apartments=total_apartments,
        active_residents=active_residents,
        open_faults=open_faults,
        pending_requests=pending_requests,
        total_dues_collected=round(total_collected, 2),
        total_dues_unpaid=round(total_unpaid, 2),
        collection_rate_pct=round(collection_rate, 1)
    )

@router.get("/resident", response_model=ResidentDashboardSummary)
def get_resident_dashboard(
    community_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """RESIDENT DASHBOARD SUMMARY (Sec 13, 96):
    Strict privacy. Shows ONLY user's personal apartment dues status and open faults."""
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    comm = db.query(Community).filter(Community.id == community_id).first()
    comm_name = comm.name if comm else ""

    # User's apartment info
    apt_member = db.query(ApartmentMember).join(Apartment).join(Block).filter(
        ApartmentMember.user_id == current_user.id,
        Block.community_id == community_id
    ).first()

    block_apt_str = "Daire Belirtilmedi"
    user_apt_ids = []
    if apt_member:
        apt = apt_member.apartment
        user_apt_ids.append(apt.id)
        block_apt_str = f"{apt.block.name} · Daire {apt.apartment_no}"

    # Dues status for user's apartment ONLY
    unpaid_dues = []
    if user_apt_ids:
        unpaid_dues = db.query(Due).filter(
            Due.community_id == community_id,
            Due.apartment_id.in_(user_apt_ids),
            Due.status.in_(["UNPAID", "PARTIAL", "OVERDUE"])
        ).all()

    # Latest announcement
    latest_ann = db.query(Announcement).filter(
        Announcement.community_id == community_id
    ).order_by(Announcement.published_at.desc()).first()

    latest_ann_out = None
    if latest_ann:
        author_name = f"{latest_ann.author.first_name} {latest_ann.author.last_name}" if latest_ann.author else "Yönetim"
        latest_ann_out = AnnouncementOut(
            id=latest_ann.id,
            community_id=latest_ann.community_id,
            author_id=latest_ann.author_id,
            author_name=author_name,
            title=latest_ann.title,
            body=latest_ann.body,
            priority=latest_ann.priority,
            attachment_url=latest_ann.attachment_url,
            published_at=latest_ann.published_at,
            expires_at=latest_ann.expires_at
        )

    # My open faults count
    my_faults_count = db.query(MaintenanceRequest).filter(
        MaintenanceRequest.community_id == community_id,
        MaintenanceRequest.reported_by == current_user.id,
        MaintenanceRequest.status.in_(["OPEN", "IN_PROGRESS", "WAITING"])
    ).count()

    # Upcoming meeting
    upcoming_meeting = db.query(Meeting).filter(
        Meeting.community_id == community_id
    ).order_by(Meeting.start_at.asc()).first()

    meeting_out = None
    if upcoming_meeting:
        meeting_out = MeetingOut(
            id=upcoming_meeting.id,
            community_id=upcoming_meeting.community_id,
            title=upcoming_meeting.title,
            description=upcoming_meeting.description,
            location=upcoming_meeting.location,
            start_at=upcoming_meeting.start_at,
            end_at=upcoming_meeting.end_at,
            created_by=upcoming_meeting.created_by,
            created_at=upcoming_meeting.created_at,
            attending_count=0,
            user_rsvp=None
        )

    # Active poll
    active_poll = db.query(Poll).filter(
        Poll.community_id == community_id,
        Poll.status == "ACTIVE"
    ).order_by(Poll.created_at.desc()).first()

    poll_out = None
    if active_poll:
        poll_out = PollOut(
            id=active_poll.id,
            community_id=active_poll.community_id,
            title=active_poll.title,
            description=active_poll.description,
            status=active_poll.status,
            is_public_result=active_poll.is_public_result,
            created_at=active_poll.created_at,
            end_at=active_poll.end_at,
            total_votes=len(active_poll.votes),
            user_voted_option_id=None,
            options=[
                PollOptionOut(
                    id=o.id,
                    poll_id=o.poll_id,
                    label=o.label,
                    vote_count=len(o.votes),
                    vote_percentage=0.0
                ) for o in active_poll.options
            ]
        )

    return ResidentDashboardSummary(
        greeting=f"Merhaba {current_user.first_name} 👋",
        community_name=comm_name,
        block_and_apartment=block_apt_str,
        has_unpaid_dues=len(unpaid_dues) > 0,
        unpaid_dues_count=len(unpaid_dues),
        latest_announcement=latest_ann_out,
        my_open_faults_count=my_faults_count,
        upcoming_meeting=meeting_out,
        active_poll=poll_out
    )
