class HomeController < ApplicationController
  def index
    @records = filter_records(params[:tags])
  end

  private

  def filter_records(selected_tags)
    if selected_tags.present?
      Record.joins(:tags)
            .where(tags: { name: selected_tags })
            .group("records.id")
            .having("COUNT(tags.id) = ?", selected_tags.size)
    else
      Record.all
    end
  end
end
