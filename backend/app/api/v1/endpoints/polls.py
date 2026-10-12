from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, require_manager_role, verify_community_membership
from app.models.all_models import User, Poll, PollOption, PollVote, CommunityMember, Notification, AuditLog
from app.schemas.all_schemas import PollCreate, PollVoteRequest, PollOut, PollOptionOut

router = APIRouter(prefix="/polls", tags=["Polls"])

@router.get("", response_model=List[PollOut])
def list_polls(
    community_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    verify_community_membership(community_id=community_id, current_user=current_user, db=db)

    polls = db.query(Poll).filter(Poll.community_id == community_id).order_by(Poll.created_at.desc()).all()
    results = []
    for p in polls:
        total_votes = db.query(PollVote).filter(PollVote.poll_id == p.id).count()

        user_vote = db.query(PollVote).filter(
            PollVote.poll_id == p.id,
            PollVote.user_id == current_user.id
        ).first()
        user_voted_opt_id = user_vote.option_id if user_vote else None

        options_out = []
        for opt in p.options:
            opt_votes = db.query(PollVote).filter(PollVote.option_id == opt.id).count()
            pct = (opt_votes / total_votes * 100) if total_votes > 0 else 0.0
            options_out.append(
                PollOptionOut(
                    id=opt.id,
                    poll_id=opt.poll_id,
                    label=opt.label,
                    vote_count=opt_votes,
                    vote_percentage=round(pct, 1)
                )
            )

        results.append(
            PollOut(
                id=p.id,
                community_id=p.community_id,
                title=p.title,
                description=p.description,
                status=p.status,
                is_public_result=p.is_public_result,
                created_at=p.created_at,
                end_at=p.end_at,
                total_votes=total_votes,
                user_voted_option_id=user_voted_opt_id,
                options=options_out
            )
        )
    return results

@router.post("", response_model=PollOut, status_code=status.HTTP_201_CREATED)
def create_poll(
    data: PollCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager_role(community_id=data.community_id, current_user=current_user, db=db)

    if len(data.options) < 2:
        raise HTTPException(status_code=400, detail="En az 2 seçenek belirtmelisiniz.")

    poll = Poll(
        community_id=data.community_id,
        title=data.title,
        description=data.description,
        end_at=data.end_at,
        created_by=current_user.id,
        status="ACTIVE",
        is_public_result=data.is_public_result
    )
    db.add(poll)
    db.commit()
    db.refresh(poll)

    options_out = []
    for opt_label in data.options:
        opt = PollOption(poll_id=poll.id, label=opt_label.strip())
        db.add(opt)
        db.commit()
        db.refresh(opt)
        options_out.append(
            PollOptionOut(
                id=opt.id,
                poll_id=opt.poll_id,
                label=opt.label,
                vote_count=0,
                vote_percentage=0.0
            )
        )

    # Notify community members
    members = db.query(CommunityMember).filter(
        CommunityMember.community_id == data.community_id,
        CommunityMember.status == "ACTIVE"
    ).all()

    for mem in members:
        if mem.user_id != current_user.id:
            notif = Notification(
                user_id=mem.user_id,
                type="POLL",
                title=f"Yeni Anket: {poll.title}",
                body="Görüşünüzü belirtmek için ankete katılabilirsiniz."
            )
            db.add(notif)
    db.commit()

    return PollOut(
        id=poll.id,
        community_id=poll.community_id,
        title=poll.title,
        description=poll.description,
        status=poll.status,
        is_public_result=poll.is_public_result,
        created_at=poll.created_at,
        end_at=poll.end_at,
        total_votes=0,
        user_voted_option_id=None,
        options=options_out
    )

@router.post("/{id}/vote")
def vote_poll(
    id: int,
    data: PollVoteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    poll = db.query(Poll).filter(Poll.id == id).first()
    if not poll:
        raise HTTPException(status_code=404, detail="Anket bulunamadı.")
    
    if poll.status != "ACTIVE":
        raise HTTPException(status_code=400, detail="Bu anket oylamaya kapatılmıştır.")

    verify_community_membership(community_id=poll.community_id, current_user=current_user, db=db)

    # Verify option belongs to this poll
    opt = db.query(PollOption).filter(PollOption.id == data.option_id, PollOption.poll_id == poll.id).first()
    if not opt:
        raise HTTPException(status_code=400, detail="Geçersiz seçenek.")

    # Check if user already voted (Single vote enforcement)
    existing_vote = db.query(PollVote).filter(
        PollVote.poll_id == poll.id,
        PollVote.user_id == current_user.id
    ).first()

    if existing_vote:
        raise HTTPException(status_code=400, detail="Bu ankete daha önce oy kullandınız. Tekrar oy veremezsiniz.")

    vote = PollVote(
        poll_id=poll.id,
        option_id=opt.id,
        user_id=current_user.id
    )
    db.add(vote)
    db.commit()

    return {"message": "Oyunuz başarıyla kaydedildi.", "option_id": opt.id}
