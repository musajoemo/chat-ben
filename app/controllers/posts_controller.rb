class PostsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:index]
  before_action :set_post, only: [:show]
  before_action :set_current_users_post, only: [:edit, :update, :destroy]

  def index
    @post = Post.new
    @posts = Post.without_deleted.from_three_weeks_ago.includes(:rooms).includes(:likes)
    @live_posts = @posts.select { |post| post.live? }
    @posts = @posts.sort_by { |post| post.sort_order }
    @posts = @posts.reject { |post| post.like_count <= -3 }
  end

  def new_chat
    post = Post.find_by_id(params[:id])

    if post.present?
      rooms = post.rooms.where('rooms.full is false').where('rooms.waiting is true')
    else
      rooms = Room.where('rooms.full is false').where('rooms.waiting is true')
      post = Post.without_deleted.from_three_weeks_ago.sample if post.blank?
    end

    room = rooms.select { |room|
      waiting_user_id = room.participations.first.try(:user_id)
      waiting_user_id.present? && !bad_rating?(waiting_user_id) && !just_chat?(waiting_user_id)
    }.first

    room = post.rooms.create if room.blank?
    room.update_attribute(:fresh, true)

    redirect_to room_path(room)
  end

  def show
    rooms = @post.rooms.where('rooms.full is false').where('rooms.waiting is true')
    room = rooms.select do |room|
      waiting_user_id = room.participations.first.try(:user_id)
      waiting_user_id.present? && !bad_rating?(waiting_user_id) && !(room.fresh? && just_chat?(waiting_user_id))
    end

    room = @post.rooms.create if room.blank?

    redirect_to room_path(room)
  end

  def new
    @post = Post.new
  end

  def edit
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user
    @post.sticky = false unless current_user.is_admin?
    @post.live = false unless current_user.is_admin?

    respond_to do |format|
      if @post.save
        room = @post.rooms.create
        format.html { redirect_to room_path(room), notice: 'Post was successfully created.' }
        format.json { render json: @post }
      else
        format.html { redirect_to root_path, alert: @post.errors.full_messages.to_sentence }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to posts_path, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post.destroy
    render nothing: true
  end

  private

  def set_current_users_post
    if current_user.is_admin?
      @post = Post.find(params[:id])
    else
      @post = current_user.posts.find(params[:id])
    end
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :link, :text_content, :sticky, :live)
  end

  def bad_rating?(user_id)
    return true if current_user.ratings.where('ratee_id = ?', user_id).where('value <= 2').any?
    return true if current_user.rateeds.where('rater_id = ?', user_id).where('value <= 2').any?
  end

  def just_chat?(user_id)
    (current_user.participations.pluck(:room_id).last(3) & User.find(user_id).participations.pluck(:room_id).last(3)).present?
  end
end
