import uuid
import datetime
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text,
    UniqueConstraint, Index, Enum as SAEnum
)
from sqlalchemy.orm import relationship
from app.core.db.base import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

def utc_now() -> datetime.datetime:
    return datetime.datetime.now(datetime.timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), default=generate_uuid, unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(32), unique=True, index=True, nullable=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    # Relationships
    memberships = relationship("CommunityMember", back_populates="user", cascade="all, delete-orphan")
    apartment_memberships = relationship("ApartmentMember", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    devices = relationship("Device", back_populates="user", cascade="all, delete-orphan")


class Community(Base):
    __tablename__ = "communities"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    type = Column(String(50), default="APARTMENT", nullable=False) # APARTMENT, SITE, RESIDENCE, COMPLEX
    address = Column(String(500), nullable=True)
    city = Column(String(100), nullable=True)
    district = Column(String(100), nullable=True)
    rules = Column(Text, nullable=True)
    emergency_contacts = Column(Text, nullable=True) # JSON or formatted string
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    # Relationships
    members = relationship("CommunityMember", back_populates="community", cascade="all, delete-orphan")
    blocks = relationship("Block", back_populates="community", cascade="all, delete-orphan")
    announcements = relationship("Announcement", back_populates="community", cascade="all, delete-orphan")
    maintenance_requests = relationship("MaintenanceRequest", back_populates="community", cascade="all, delete-orphan")
    dues = relationship("Due", back_populates="community", cascade="all, delete-orphan")
    meetings = relationship("Meeting", back_populates="community", cascade="all, delete-orphan")
    polls = relationship("Poll", back_populates="community", cascade="all, delete-orphan")
    invite_codes = relationship("CommunityInviteCode", back_populates="community", cascade="all, delete-orphan")


class CommunityInviteCode(Base):
    __tablename__ = "community_invite_codes"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    code = Column(String(32), unique=True, index=True, nullable=False)
    valid_until = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    community = relationship("Community", back_populates="invite_codes")


class CommunityMember(Base):
    __tablename__ = "community_members"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(50), default="RESIDENT", nullable=False) # RESIDENT, MANAGER, ASSISTANT_MANAGER, SUPER_ADMIN
    status = Column(String(50), default="PENDING", nullable=False) # ACTIVE, PENDING, REJECTED
    joined_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    user = relationship("User", back_populates="memberships")
    community = relationship("Community", back_populates="members")

    __table_args__ = (
        UniqueConstraint("community_id", "user_id", name="uq_community_user"),
        Index("ix_cm_comm_role", "community_id", "role"),
    )


class Block(Base):
    __tablename__ = "blocks"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)

    community = relationship("Community", back_populates="blocks")
    apartments = relationship("Apartment", back_populates="block", cascade="all, delete-orphan")


class Apartment(Base):
    __tablename__ = "apartments"

    id = Column(Integer, primary_key=True, index=True)
    block_id = Column(Integer, ForeignKey("blocks.id", ondelete="CASCADE"), nullable=False, index=True)
    apartment_no = Column(String(50), nullable=False)
    floor = Column(Integer, nullable=True)
    type = Column(String(50), nullable=True) # 2+1, 3+1, etc.

    block = relationship("Block", back_populates="apartments")
    members = relationship("ApartmentMember", back_populates="apartment", cascade="all, delete-orphan")
    dues = relationship("Due", back_populates="apartment", cascade="all, delete-orphan")
    maintenance_requests = relationship("MaintenanceRequest", back_populates="apartment", cascade="all, delete-orphan")


class ApartmentMember(Base):
    __tablename__ = "apartment_members"

    id = Column(Integer, primary_key=True, index=True)
    apartment_id = Column(Integer, ForeignKey("apartments.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    is_owner = Column(Boolean, default=False, nullable=False)
    is_primary_resident = Column(Boolean, default=True, nullable=False)
    joined_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    apartment = relationship("Apartment", back_populates="members")
    user = relationship("User", back_populates="apartment_memberships")

    __table_args__ = (
        UniqueConstraint("apartment_id", "user_id", name="uq_apartment_user"),
    )


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    author_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    priority = Column(String(50), default="NORMAL", nullable=False) # NORMAL, IMPORTANT, URGENT
    attachment_url = Column(String(500), nullable=True)
    published_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    community = relationship("Community", back_populates="announcements")
    author = relationship("User")

    __table_args__ = (
        Index("ix_announcements_comm_date", "community_id", "published_at"),
    )


class MaintenanceRequest(Base):
    __tablename__ = "maintenance_requests"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    apartment_id = Column(Integer, ForeignKey("apartments.id", ondelete="SET NULL"), nullable=True, index=True)
    reported_by = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category = Column(String(100), default="OTHER", nullable=False) # ELEVATOR, WATER, ELECTRICITY, etc.
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(50), default="OPEN", nullable=False) # OPEN, IN_PROGRESS, WAITING, RESOLVED, CLOSED
    priority = Column(String(50), default="NORMAL", nullable=False)
    photo_url = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    community = relationship("Community", back_populates="maintenance_requests")
    apartment = relationship("Apartment", back_populates="maintenance_requests")
    reporter = relationship("User", foreign_keys=[reported_by])
    comments = relationship("MaintenanceComment", back_populates="request", cascade="all, delete-orphan")

    __table_args__ = (
        Index("ix_maint_comm_status", "community_id", "status"),
        Index("ix_maint_reporter", "reported_by"),
    )


class MaintenanceComment(Base):
    __tablename__ = "maintenance_comments"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("maintenance_requests.id", ondelete="CASCADE"), nullable=False, index=True)
    author_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    body = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    request = relationship("MaintenanceRequest", back_populates="comments")
    author = relationship("User")


class Meeting(Base):
    __tablename__ = "meetings"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    location = Column(String(255), nullable=False)
    start_at = Column(DateTime(timezone=True), nullable=False)
    end_at = Column(DateTime(timezone=True), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    community = relationship("Community", back_populates="meetings")
    creator = relationship("User", foreign_keys=[created_by])
    attendees = relationship("MeetingAttendee", back_populates="meeting", cascade="all, delete-orphan")


class MeetingAttendee(Base):
    __tablename__ = "meeting_attendees"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(String(50), default="ATTENDING", nullable=False) # ATTENDING, NOT_ATTENDING, TENTATIVE
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    meeting = relationship("Meeting", back_populates="attendees")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint("meeting_id", "user_id", name="uq_meeting_user"),
    )


class Poll(Base):
    __tablename__ = "polls"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    start_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    end_at = Column(DateTime(timezone=True), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(50), default="ACTIVE", nullable=False) # ACTIVE, CLOSED
    is_public_result = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    community = relationship("Community", back_populates="polls")
    creator = relationship("User", foreign_keys=[created_by])
    options = relationship("PollOption", back_populates="poll", cascade="all, delete-orphan")
    votes = relationship("PollVote", back_populates="poll", cascade="all, delete-orphan")


class PollOption(Base):
    __tablename__ = "poll_options"

    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id", ondelete="CASCADE"), nullable=False, index=True)
    label = Column(String(255), nullable=False)

    poll = relationship("Poll", back_populates="options")
    votes = relationship("PollVote", back_populates="option", cascade="all, delete-orphan")


class PollVote(Base):
    __tablename__ = "poll_votes"

    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id", ondelete="CASCADE"), nullable=False, index=True)
    option_id = Column(Integer, ForeignKey("poll_options.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    poll = relationship("Poll", back_populates="votes")
    option = relationship("PollOption", back_populates="votes")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint("poll_id", "user_id", name="uq_poll_user_vote"),
    )


class Due(Base):
    __tablename__ = "dues"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    apartment_id = Column(Integer, ForeignKey("apartments.id", ondelete="CASCADE"), nullable=False, index=True)
    period = Column(String(50), nullable=False) # e.g. "Ekim 2026", "2026-10"
    amount = Column(Float, nullable=False)
    due_date = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(50), default="UNPAID", nullable=False) # UNPAID, PAID, PARTIAL, OVERDUE
    notes = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    community = relationship("Community", back_populates="dues")
    apartment = relationship("Apartment", back_populates="dues")
    payments = relationship("DuePayment", back_populates="due", cascade="all, delete-orphan")

    __table_args__ = (
        Index("ix_dues_comm_apt", "community_id", "apartment_id"),
        Index("ix_dues_status_date", "status", "due_date"),
    )


class DuePayment(Base):
    __tablename__ = "dues_payments"

    id = Column(Integer, primary_key=True, index=True)
    due_id = Column(Integer, ForeignKey("dues.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    paid_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    payment_method = Column(String(50), default="BANK_TRANSFER", nullable=False) # BANK_TRANSFER, CASH, CREDIT_CARD, OTHER
    reference = Column(String(255), nullable=True)

    due = relationship("Due", back_populates="payments")


class PrivateMessage(Base):
    __tablename__ = "private_messages"

    id = Column(Integer, primary_key=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subject = Column(String(255), nullable=True)
    body = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    read_at = Column(DateTime(timezone=True), nullable=True)

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    __table_args__ = (
        Index("ix_msg_receiver_sender", "receiver_id", "sender_id"),
    )


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    type = Column(String(50), nullable=False) # ANNOUNCEMENT, MAINTENANCE, MEETING, POLL, PRIVATE_MESSAGE, DUES_REMINDER, IMPORTANT
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    user = relationship("User", back_populates="notifications")

    __table_args__ = (
        Index("ix_notif_user_read", "user_id", "is_read"),
    )


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    platform = Column(String(50), nullable=False) # ANDROID, IOS, WEB
    push_token = Column(String(500), nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    user = relationship("User", back_populates="devices")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    actor_user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    community_id = Column(Integer, ForeignKey("communities.id", ondelete="CASCADE"), nullable=True, index=True)
    action = Column(String(100), nullable=False) # e.g. MANAGER_CREATED_DUE, MANAGER_UPDATED_MAINTENANCE
    entity_type = Column(String(50), nullable=False) # DUE, MAINTENANCE, ANNOUNCEMENT, etc.
    entity_id = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
