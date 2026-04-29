# frozen_string_literal: true

##
# Reports Controller
#
# Handles all reporting and analytics pages.
# Uses DataAggregator service to efficiently retrieve and display aggregated data.
#
# All aggregation operations use database-level queries for optimal performance.
#
class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :initialize_aggregator

  # Dashboard report - comprehensive overview of all data
  def dashboard
    @summary = @aggregator.dashboard_summary
    @page_title = "Analytics Dashboard"
  end

  # Records analysis report
  def records_analysis
    @records_count = @aggregator.record_count_statistics
    @records_by_tag = @aggregator.records_by_tag
    @records_by_user = @aggregator.records_by_user
    @average_dimensions = @aggregator.average_dimensions
    @dimension_range = @aggregator.dimension_range_statistics
    @average_dimensions_by_tag = @aggregator.average_dimensions_by_tag
    @dimension_distribution = @aggregator.complexity_score_distribution
    @most_tagged = @aggregator.most_tagged_records(limit: 10)
    @least_tagged = @aggregator.least_tagged_records(limit: 10)
    @page_title = "Records Analysis"
  end

  # Software analysis report
  def software_analysis
    @software_stats = @aggregator.software_performance_stats
    @software_usage = @aggregator.software_usage_frequency(limit: 20)
    @software_by_performance = @aggregator.software_usage_frequency(limit: 10)
    @page_title = "Software Analysis"
  end

  # Tags analysis report
  def tags_analysis
    @tag_distribution = @aggregator.tag_distribution_stats
    @records_by_tag = @aggregator.records_by_tag
    @tag_cooccurrence = @aggregator.tag_cooccurrence(limit: 15)
    @page_title = "Tags Analysis"
  end

  # User contributions report
  def user_analysis
    @user_stats = @aggregator.user_contribution_stats
    @user_records_count = @aggregator.records_by_user
    @page_title = "User Contributions"
  end

  # Complexity analysis report
  def complexity_analysis
    @complexity_distribution = @aggregator.complexity_score_distribution
    @average_dimensions_by_tag = @aggregator.average_dimensions_by_tag
    @most_complex = Record.with_complexity.by_complexity.limit(10)
    @least_complex = Record.with_complexity.order(complexity_score: :asc).limit(10)
    @page_title = "Complexity Analysis"
  end

  # Timeline report - creation patterns over time
  def timeline_analysis
    @timeline_monthly = @aggregator.creation_timeline(period: 'month', limit: 12)
    @timeline_weekly = @aggregator.creation_timeline(period: 'week', limit: 24)
    @page_title = "Timeline Analysis"
  end

  # Export data in CSV format
  def export_csv
    report_type = params[:report_type] || 'dashboard'
    
    case report_type
    when 'records'
      export_records_csv
    when 'software'
      export_software_csv
    when 'tags'
      export_tags_csv
    when 'users'
      export_users_csv
    else
      redirect_to reports_dashboard_path, alert: 'Invalid report type'
    end
  end

  private

  def initialize_aggregator
    @aggregator = DataAggregator.new
  end

  def export_records_csv
    data = @aggregator.average_dimensions_by_tag
    csv_data = CSV.generate do |csv|
      csv << ['Tag Name', 'Avg Width', 'Avg Height', 'Avg Depth', 'Record Count']
      data.each do |row|
        csv << [row[:name], row[:width], row[:height], row[:depth], row[:count]]
      end
    end
    
    send_data csv_data, filename: "records_analysis_#{Time.current.to_date}.csv"
  end

  def export_software_csv
    data = @aggregator.software_usage_frequency(limit: 100)
    csv_data = CSV.generate do |csv|
      csv << ['Software Name', 'Usage Count']
      data.each do |row|
        csv << [row[:name], row[:count]]
      end
    end
    
    send_data csv_data, filename: "software_analysis_#{Time.current.to_date}.csv"
  end

  def export_tags_csv
    data = @aggregator.records_by_tag
    csv_data = CSV.generate do |csv|
      csv << ['Tag Name', 'Record Count']
      data.each do |row|
        csv << [row[:name], row[:count]]
      end
    end
    
    send_data csv_data, filename: "tags_analysis_#{Time.current.to_date}.csv"
  end

  def export_users_csv
    data = @aggregator.user_contribution_stats
    csv_data = CSV.generate do |csv|
      csv << ['User Name', 'Record Count', 'Avg Complexity', 'Max Complexity']
      data.each do |row|
        csv << [row[:name], row[:record_count], row[:avg_complexity], row[:max_complexity]]
      end
    end
    
    send_data csv_data, filename: "user_analysis_#{Time.current.to_date}.csv"
  end
end
