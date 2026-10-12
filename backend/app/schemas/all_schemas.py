import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, ConfigDict

# ----------------- AUTH & USER -----------------
class UserCreate(BaseModel):
    email: EmailStr
    phone: Optional[str] = None
    password: str = Field(..., min_length=6)
    first_name: str = Field(..., min_length=1)
    last_name: str = Field(..., min_length=1)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: int
    email: str
    first_name: str
    last_name: str
    role: str

class TokenRefresh(BaseModel):
    refresh_token: str

class UserOut(BaseModel):
    id: int
    uuid: str
    email: str
    phone: Optional[str] = None
    first_name: str
    last_name: str
    avatar_url: Optional[str] = None
    is_active: bool
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    reset_token: str
    new_password: str = Field(..., min_length=6)

# ----------------- COMMUNITY & APARTMENT -----------------
class CommunityCreate(BaseModel):
    name: str = Field(..., min_length=2)
    type: str = "APARTMENT"
    address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None

class CommunityOut(BaseModel):
    id: int
    name: str
    type: str
    address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    rules: Optional[str] = None
    emergency_contacts: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class BlockCreate(BaseModel):
    name: str

class BlockOut(BaseModel):
    id: int
    community_id: int
    name: str

    model_config = ConfigDict(from_attributes=True)

class ApartmentCreate(BaseModel):
    apartment_no: str
    floor: Optional[int] = None
    type: Optional[str] = None

class ApartmentOut(BaseModel):
    id: int
    block_id: int
    apartment_no: str
    floor: Optional[int] = None
    type: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class CommunityMemberOut(BaseModel):
    id: int
    community_id: int
    user_id: int
    role: str
    status: str
    joined_at: datetime.datetime
    user: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

class CommunityJoinRequest(BaseModel):
    invite_code: str
    apartment_id: int
    is_owner: bool = False

# ----------------- ANNOUNCEMENTS -----------------
class AnnouncementCreate(BaseModel):
    community_id: int
    title: str = Field(..., min_length=3)
    body: str = Field(..., min_length=5)
    priority: str = "NORMAL" # NORMAL, IMPORTANT, URGENT
    attachment_url: Optional[str] = None
    expires_at: Optional[datetime.datetime] = None

class AnnouncementUpdate(BaseModel):
    title: Optional[str] = None
    body: Optional[str] = None
    priority: Optional[str] = None
    attachment_url: Optional[str] = None
    expires_at: Optional[datetime.datetime] = None

class AnnouncementOut(BaseModel):
    id: int
    community_id: int
    author_id: Optional[int] = None
    author_name: Optional[str] = None
    title: str
    body: str
    priority: str
    attachment_url: Optional[str] = None
    published_at: datetime.datetime
    expires_at: Optional[datetime.datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ----------------- MAINTENANCE -----------------
class MaintenanceCreate(BaseModel):
    community_id: int
    apartment_id: Optional[int] = None
    category: str = "OTHER"
    title: str = Field(..., min_length=3)
    description: str = Field(..., min_length=5)
    priority: str = "NORMAL"
    photo_url: Optional[str] = None

class MaintenanceUpdate(BaseModel):
    status: Optional[str] = None # OPEN, IN_PROGRESS, WAITING, RESOLVED, CLOSED
    priority: Optional[str] = None

class MaintenanceCommentCreate(BaseModel):
    body: str = Field(..., min_length=1)

class MaintenanceCommentOut(BaseModel):
    id: int
    request_id: int
    author_id: int
    author_name: Optional[str] = None
    body: str
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class MaintenanceOut(BaseModel):
    id: int
    community_id: int
    apartment_id: Optional[int] = None
    reported_by: int
    reporter_name: Optional[str] = None
    category: str
    title: str
    description: str
    status: str
    priority: str
    photo_url: Optional[str] = None
    created_at: datetime.datetime
    resolved_at: Optional[datetime.datetime] = None
    comments: List[MaintenanceCommentOut] = []

    model_config = ConfigDict(from_attributes=True)

# ----------------- MEETINGS -----------------
class MeetingCreate(BaseModel):
    community_id: int
    title: str = Field(..., min_length=3)
    description: Optional[str] = None
    location: str
    start_at: datetime.datetime
    end_at: Optional[datetime.datetime] = None

class MeetingRSVPRequest(BaseModel):
    status: str = "ATTENDING" # ATTENDING, NOT_ATTENDING, TENTATIVE

class MeetingOut(BaseModel):
    id: int
    community_id: int
    title: str
    description: Optional[str] = None
    location: str
    start_at: datetime.datetime
    end_at: Optional[datetime.datetime] = None
    created_by: Optional[int] = None
    created_at: datetime.datetime
    attending_count: int = 0
    user_rsvp: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

# ----------------- POLLS -----------------
class PollOptionCreate(BaseModel):
    label: str = Field(..., min_length=1)

class PollCreate(BaseModel):
    community_id: int
    title: str = Field(..., min_length=3)
    description: Optional[str] = None
    end_at: Optional[datetime.datetime] = None
    is_public_result: bool = True
    options: List[str] = Field(..., min_length=2)

class PollVoteRequest(BaseModel):
    option_id: int

class PollOptionOut(BaseModel):
    id: int
    poll_id: int
    label: str
    vote_count: int = 0
    vote_percentage: float = 0.0

    model_config = ConfigDict(from_attributes=True)

class PollOut(BaseModel):
    id: int
    community_id: int
    title: str
    description: Optional[str] = None
    status: str
    is_public_result: bool
    created_at: datetime.datetime
    end_at: Optional[datetime.datetime] = None
    total_votes: int = 0
    user_voted_option_id: Optional[int] = None
    options: List[PollOptionOut] = []

    model_config = ConfigDict(from_attributes=True)

# ----------------- DUES (PRIVACY STRICT) -----------------
class DueCreate(BaseModel):
    community_id: int
    apartment_id: int
    period: str
    amount: float = Field(..., gt=0)
    due_date: datetime.datetime
    notes: Optional[str] = None

class DuePaymentCreate(BaseModel):
    amount: float = Field(..., gt=0)
    payment_method: str = "BANK_TRANSFER"
    reference: Optional[str] = None

class DuePaymentOut(BaseModel):
    id: int
    due_id: int
    amount: float
    paid_at: datetime.datetime
    payment_method: str
    reference: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class DueOut(BaseModel):
    id: int
    community_id: int
    apartment_id: int
    block_name: Optional[str] = None
    apartment_no: Optional[str] = None
    period: str
    amount: float
    due_date: datetime.datetime
    status: str
    notes: Optional[str] = None
    created_at: datetime.datetime
    payments: List[DuePaymentOut] = []

    model_config = ConfigDict(from_attributes=True)

# ----------------- PRIVATE MESSAGES -----------------
class MessageCreate(BaseModel):
    community_id: int
    receiver_id: int
    subject: Optional[str] = None
    body: str = Field(..., min_length=1)

class MessageOut(BaseModel):
    id: int
    community_id: int
    sender_id: int
    sender_name: Optional[str] = None
    receiver_id: int
    receiver_name: Optional[str] = None
    subject: Optional[str] = None
    body: str
    created_at: datetime.datetime
    read_at: Optional[datetime.datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ----------------- NOTIFICATIONS & DEVICES -----------------
class NotificationOut(BaseModel):
    id: int
    user_id: int
    type: str
    title: str
    body: str
    is_read: bool
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class DeviceRegister(BaseModel):
    platform: str
    push_token: str

# ----------------- DASHBOARD STATS -----------------
class ManagerDashboardStats(BaseModel):
    total_apartments: int
    active_residents: int
    open_faults: int
    pending_requests: int
    total_dues_collected: float
    total_dues_unpaid: float
    collection_rate_pct: float

class ResidentDashboardSummary(BaseModel):
    greeting: str
    community_name: str
    block_and_apartment: str
    has_unpaid_dues: bool
    unpaid_dues_count: int
    latest_announcement: Optional[AnnouncementOut] = None
    my_open_faults_count: int = 0
    upcoming_meeting: Optional[MeetingOut] = None
    active_poll: Optional[PollOut] = None
