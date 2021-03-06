class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :update]

  skip_before_filter :authenticate_user!, only: [:show]

  def update
    @room.update_attribute(:waiting, false) # all you can update is that you are no long waiting when you leave
    render nothing: true
  end

  def show
    @bins = Bin.without_deleted.includes(:posts).order('post_bins.position asc').order(:position)
    @post = Post.new
    @hide_footer = true

    redirect_to root_url and return unless @room

    Participation.find_or_create_by(user: current_user, room: @room) if current_user
    @rating = Rating.new
  end

  def set_room
    @room = Room.where('token = ?', params['token']).first
  end
end
