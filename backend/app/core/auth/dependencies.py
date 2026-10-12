from typing import Optional, List
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.security import decode_token
from app.models.all_models import User, CommunityMember, ApartmentMember

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Geçersiz kimlik doğrulama bilgisi.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            raise credentials_exception
        user_id = int(user_id_str)
    except Exception:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if user is None:
        raise credentials_exception
    return user


def verify_community_membership(
    community_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CommunityMember:
    """Verifies that the current user is an active member of the specified community (Multi-Tenant Isolation)."""
    member = db.query(CommunityMember).filter(
        CommunityMember.community_id == community_id,
        CommunityMember.user_id == current_user.id,
        CommunityMember.status == "ACTIVE"
    ).first()
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu bina/site için aktif üyeliğiniz bulunmuyor."
        )
    return member


def require_manager_role(
    community_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CommunityMember:
    """Verifies that the current user has MANAGER or ASSISTANT_MANAGER role in the community."""
    member = db.query(CommunityMember).filter(
        CommunityMember.community_id == community_id,
        CommunityMember.user_id == current_user.id,
        CommunityMember.status == "ACTIVE"
    ).first()
    if not member or member.role not in ["MANAGER", "ASSISTANT_MANAGER", "SUPER_ADMIN"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu işlem için yönetici yetkisi gerekmektedir."
        )
    return member


def get_user_apartments(user_id: int, db: Session) -> List[int]:
    """Returns list of apartment_ids belonging to the given user."""
    memberships = db.query(ApartmentMember).filter(ApartmentMember.user_id == user_id).all()
    return [m.apartment_id for m in memberships]
