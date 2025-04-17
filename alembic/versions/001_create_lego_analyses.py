"""create lego analyses table

Revision ID: 001
Revises: 
Create Date: 2024-04-11 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'lego_analyses',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('original_image_url', sa.String(255), nullable=False),
        sa.Column('lego_image_url', sa.String(255)),
        sa.Column('confidence_score', sa.Float(), default=0.0),
        sa.Column('status', sa.String(20), default='pending'),
        sa.Column('error_message', sa.String(255)),
        sa.Column('parts_list', JSONB, default=list),
        sa.Column('total_price', sa.Float(), default=0.0),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), onupdate=sa.text('CURRENT_TIMESTAMP')),
        sa.Index('idx_user_id', 'user_id'),
        sa.Index('idx_status', 'status')
    )

def downgrade() -> None:
    op.drop_table('lego_analyses') 