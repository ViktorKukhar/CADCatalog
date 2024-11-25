class HomeController < ApplicationController
  def index
    @records = filter_records(params[:tags], params[:softwares])
  end

  private

  def filter_records(selected_tags, selected_softwares)
    records = Record.all

    # Filter by tags if provided
    if selected_tags.present?
      records = records.joins(:tags)
                       .where(tags: { name: selected_tags })
                       .group("records.id")
                       .having("COUNT(tags.id) = ?", selected_tags.size)
    end

    # Filter by software if provided
    if selected_softwares.present?
      records = records.joins(:softwares)
                       .where(softwares: { name: selected_softwares })
                       .group("records.id")
                       .having("COUNT(softwares.id) = ?", selected_softwares.size)
    end

    records
  end
end
