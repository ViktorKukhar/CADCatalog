class RecordsController < ApplicationController
  before_action :set_record, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new ]

  def index
    if params[:tag]
      @records = Record.joins(:tags).where(tags: { name: params[:tag] }).distinct
      @tag = Tag.find_by(name: params[:tag])
    else
      @records = Record.all
    end
  end

  def show
    @record = Record.find(params[:id])
    @user_records = Record.where(user_id: @record.user_id).where.not(id: @record.id)
  end

  def new
    @record = Record.new(user: current_user)
  end

  def edit

  end

  def create
    @record = current_user.records.build(record_params)

      if @record.save
        redirect_to @record, notice: "Record was successfully created."
      else
        render :new
      end
  end

  def update
    if @record.update(record_params)
      redirect_to @record, notice: 'Record was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @record.destroy
    redirect_to records_url, notice: 'Record was successfully destroyed.'
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def record_params
    params.require(:record).permit(:title, :description, :user_id, :tag_list, files: [], images: [])
  end
end
