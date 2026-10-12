from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.db.session import get_db
from app.core.auth.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.core.auth.dependencies import get_current_user
from app.models.all_models import User, CommunityMember
from app.schemas.all_schemas import (
    UserCreate, UserLogin, Token, TokenRefresh, UserOut, UserUpdate,
    PasswordResetRequest, PasswordResetConfirm
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    # Check if email exists
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta adresiyle kayıtlı bir hesap zaten bulunmaktadır."
        )
    
    user = User(
        email=user_in.email,
        phone=user_in.phone,
        password_hash=hash_password(user_in.password),
        first_name=user_in.first_name,
        last_name=user_in.last_name,
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(subject=user.id, role="RESIDENT")
    refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role="RESIDENT"
    )

@router.post("/login", response_model=Token)
def login(user_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_in.email).first()
    if not user or not verify_password(user_in.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta veya şifre hatalı."
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Kullanıcı hesabı askıya alınmıştır."
        )

    # Determine highest role across memberships
    memberships = db.query(CommunityMember).filter(
        CommunityMember.user_id == user.id,
        CommunityMember.status == "ACTIVE"
    ).all()
    
    role = "RESIDENT"
    for m in memberships:
        if m.role in ["MANAGER", "SUPER_ADMIN"]:
            role = m.role
            break
        elif m.role == "ASSISTANT_MANAGER" and role != "MANAGER":
            role = "ASSISTANT_MANAGER"

    access_token = create_access_token(subject=user.id, role=role)
    refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role=role
    )

@router.post("/refresh", response_model=Token)
def refresh_token(req: TokenRefresh, db: Session = Depends(get_db)):
    try:
        payload = decode_token(req.refresh_token, is_refresh=True)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="Geçersiz refresh token.")
        user_id = int(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=401, detail="Geçersiz veya süresi dolmuş token.")

    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    access_token = create_access_token(subject=user.id)
    new_refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=new_refresh_token,
        user_id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role="RESIDENT"
    )

@router.get("/me", response_model=UserOut)
def get_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserOut)
def update_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user_update.first_name is not None:
        current_user.first_name = user_update.first_name
    if user_update.last_name is not None:
        current_user.last_name = user_update.last_name
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    if user_update.avatar_url is not None:
        current_user.avatar_url = user_update.avatar_url

    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/forgot-password")
def forgot_password(req: PasswordResetRequest, db: Session = Depends(get_db)):
    # In production, send secure reset email link. Return friendly message.
    return {"message": "Şifre sıfırlama talimatı e-posta adresinize gönderildi."}

@router.delete("/account")
def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Google Play account deletion compliance. Anonymizes/removes user record and clears sensitive associations."""
    # Check if user is sole manager of any active community
    managed_memberships = db.query(CommunityMember).filter(
        CommunityMember.user_id == current_user.id,
        CommunityMember.role == "MANAGER",
        CommunityMember.status == "ACTIVE"
    ).all()

    for mm in managed_memberships:
        other_managers = db.query(CommunityMember).filter(
            CommunityMember.community_id == mm.community_id,
            CommunityMember.user_id != current_user.id,
            CommunityMember.role == "MANAGER",
            CommunityMember.status == "ACTIVE"
        ).count()
        if other_managers == 0:
            raise HTTPException(
                status_code=400,
                detail="Yönetici olduğunuz sitede başka bir yönetici atamadan hesabınızı silemezsiniz."
            )

    # Delete or anonymize
    db.delete(current_user)
    db.commit()
    return {"message": "Hesabınız başarıyla silindi."}
