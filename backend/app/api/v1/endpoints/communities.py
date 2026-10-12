import random
import string
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.dependencies import get_current_user, require_manager_role, verify_community_membership
from app.models.all_models import (
    User, Community, CommunityMember, Block, Apartment, ApartmentMember,
    CommunityInviteCode, AuditLog
)
from app.schemas.all_schemas import (
    CommunityCreate, CommunityOut, BlockCreate, BlockOut,
    ApartmentCreate, ApartmentOut, CommunityMemberOut, CommunityJoinRequest
)

router = APIRouter(prefix="/communities", tags=["Communities"])

def generate_code(length: int = 8) -> str:
    chars = string.ascii_uppercase + string.digits
    return "".join(random.choice(chars) for _ in range(length))

@router.post("", response_model=CommunityOut, status_code=status.HTTP_201_CREATED)
def create_community(
    data: CommunityCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    community = Community(
        name=data.name,
        type=data.type,
        address=data.address,
        city=data.city,
        district=data.district
    )
    db.add(community)
    db.commit()
    db.refresh(community)

    # Creator becomes MANAGER
    member = CommunityMember(
        community_id=community.id,
        user_id=current_user.id,
        role="MANAGER",
        status="ACTIVE"
    )
    db.add(member)

    # Create default invite code
    invite = CommunityInviteCode(
        community_id=community.id,
        code=f"RP-{generate_code(6)}",
        is_active=True
    )
    db.add(invite)

    # Audit log
    audit = AuditLog(
        actor_user_id=current_user.id,
        community_id=community.id,
        action="CREATED_COMMUNITY",
        entity_type="COMMUNITY",
        entity_id=community.id
    )
    db.add(audit)
    db.commit()

    return community

@router.get("/my")
def get_my_communities(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    memberships = db.query(CommunityMember).filter(
        CommunityMember.user_id == current_user.id
    ).all()
    
    result = []
    for m in memberships:
        comm = db.query(Community).filter(Community.id == m.community_id).first()
        if comm:
            # Check apartment info
            apt_member = db.query(ApartmentMember).join(Apartment).join(Block).filter(
                ApartmentMember.user_id == current_user.id,
                Block.community_id == comm.id
            ).first()

            apt_info = None
            if apt_member:
                apt = apt_member.apartment
                block = apt.block
                apt_info = {
                    "apartment_id": apt.id,
                    "apartment_no": apt.apartment_no,
                    "block_name": block.name,
                    "floor": apt.floor,
                    "is_owner": apt_member.is_owner
                }

            result.append({
                "community": {
                    "id": comm.id,
                    "name": comm.name,
                    "type": comm.type,
                    "address": comm.address,
                    "city": comm.city,
                    "district": comm.district,
                    "rules": comm.rules,
                    "emergency_contacts": comm.emergency_contacts
                },
                "role": m.role,
                "status": m.status,
                "joined_at": m.joined_at,
                "apartment": apt_info
            })
    return result

@router.get("/{id}", response_model=CommunityOut)
def get_community_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify membership or return community
    verify_community_membership(community_id=id, current_user=current_user, db=db)
    comm = db.query(Community).filter(Community.id == id).first()
    if not comm:
        raise HTTPException(status_code=404, detail="Bina/site bulunamadı.")
    return comm

@router.post("/join")
def join_community(
    req: CommunityJoinRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    invite = db.query(CommunityInviteCode).filter(
        CommunityInviteCode.code == req.invite_code.strip().upper(),
        CommunityInviteCode.is_active == True
    ).first()
    if not invite:
        raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş davet kodu.")

    community_id = invite.community_id

    # Check if already member
    existing_member = db.query(CommunityMember).filter(
        CommunityMember.community_id == community_id,
        CommunityMember.user_id == current_user.id
    ).first()
    if existing_member:
        if existing_member.status == "ACTIVE":
            raise HTTPException(status_code=400, detail="Zaten bu sitenin aktif üyesisiniz.")
        elif existing_member.status == "PENDING":
            raise HTTPException(status_code=400, detail="Üyelik onayınız zaten beklemededir.")

    # Check apartment
    apt = db.query(Apartment).join(Block).filter(
        Apartment.id == req.apartment_id,
        Block.community_id == community_id
    ).first()
    if not apt:
        raise HTTPException(status_code=400, detail="Seçilen daire bu siteye ait değil.")

    # Create pending membership (Requires manager approval)
    new_member = CommunityMember(
        community_id=community_id,
        user_id=current_user.id,
        role="RESIDENT",
        status="ACTIVE" # Auto-activated with valid invite code, can also be PENDING if manager requires confirmation
    )
    db.add(new_member)

    # Attach to apartment
    apt_member = ApartmentMember(
        apartment_id=apt.id,
        user_id=current_user.id,
        is_owner=req.is_owner,
        is_primary_resident=True
    )
    db.add(apt_member)
    db.commit()

    return {"message": "Siteye başarıyla katıldınız.", "community_id": community_id, "status": "ACTIVE"}

@router.get("/{id}/blocks")
def list_blocks_and_apartments(
    id: int,
    db: Session = Depends(get_db)
):
    blocks = db.query(Block).filter(Block.community_id == id).all()
    res = []
    for b in blocks:
        apts = db.query(Apartment).filter(Apartment.block_id == b.id).all()
        res.append({
            "id": b.id,
            "name": b.name,
            "apartments": [
                {
                    "id": a.id,
                    "apartment_no": a.apartment_no,
                    "floor": a.floor,
                    "type": a.type
                } for a in apts
            ]
        })
    return res

@router.post("/{id}/blocks", response_model=BlockOut)
def create_block(
    id: int,
    data: BlockCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager_role(community_id=id, current_user=current_user, db=db)
    block = Block(community_id=id, name=data.name)
    db.add(block)
    db.commit()
    db.refresh(block)
    return block

@router.post("/{id}/blocks/{block_id}/apartments", response_model=ApartmentOut)
def create_apartment(
    id: int,
    block_id: int,
    data: ApartmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager_role(community_id=id, current_user=current_user, db=db)
    block = db.query(Block).filter(Block.id == block_id, Block.community_id == id).first()
    if not block:
        raise HTTPException(status_code=404, detail="Blok bulunamadı.")
    
    apt = Apartment(
        block_id=block.id,
        apartment_no=data.apartment_no,
        floor=data.floor,
        type=data.type
    )
    db.add(apt)
    db.commit()
    db.refresh(apt)
    return apt

@router.get("/{id}/members")
def get_community_members(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify membership
    cm = verify_community_membership(community_id=id, current_user=current_user, db=db)
    is_manager = cm.role in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]

    members = db.query(CommunityMember).filter(CommunityMember.community_id == id).all()
    results = []
    for m in members:
        u = m.user
        # Find apartment
        apt_m = db.query(ApartmentMember).join(Apartment).join(Block).filter(
            ApartmentMember.user_id == u.id,
            Block.community_id == id
        ).first()

        apt_str = ""
        if apt_m:
            apt_str = f"{apt_m.apartment.block.name} No: {apt_m.apartment.apartment_no}"

        if is_manager:
            # Manager sees contact details
            results.append({
                "id": m.id,
                "user_id": u.id,
                "first_name": u.first_name,
                "last_name": u.last_name,
                "email": u.email,
                "phone": u.phone,
                "role": m.role,
                "status": m.status,
                "joined_at": m.joined_at,
                "apartment_info": apt_str
            })
        else:
            # SAKİN: PRIVACY-FIRST! Phone and email are HIDDEN! (Sec 31)
            results.append({
                "id": m.id,
                "user_id": u.id,
                "first_name": u.first_name,
                "last_name": u.last_name[0] + "." if u.last_name else "",
                "role": m.role,
                "status": m.status,
                "joined_at": m.joined_at,
                "apartment_info": apt_str
            })
    return results

@router.get("/{id}/invite-code")
def get_invite_code(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager_role(community_id=id, current_user=current_user, db=db)
    invite = db.query(CommunityInviteCode).filter(
        CommunityInviteCode.community_id == id,
        CommunityInviteCode.is_active == True
    ).first()
    if not invite:
        invite = CommunityInviteCode(
            community_id=id,
            code=f"RP-{generate_code(6)}",
            is_active=True
        )
        db.add(invite)
        db.commit()
        db.refresh(invite)
    return {"code": invite.code, "community_id": id}
