# NavigationBuilder - Rails Framework Navigation System
# Implements uniform, isolated, and maintainable navigation logic
# Extracts navigation principles into a single, reusable system

class NavigationBuilder
  # Represents a single navigation item with path and metadata
  NavigationItem = Struct.new(:label, :path, :icon, :active, :children, :badge) do
    def active?
      active == true
    end
  end

  # Initializes navigation builder with current request context
  # Uses Rails request object for determining active routes
  def initialize(current_user = nil, current_request = nil)
    @current_user = current_user
    @current_request = current_request
    @current_path = current_request&.path
    @current_route = current_request&.url
  end

  # Builds main application navigation menu
  # Uses Rails routing helpers to generate paths
  def main_navigation
    [
      NavigationItem.new(
        'Dashboard',
        Rails.application.routes.url_helpers.root_path,
        'home',
        is_active?('root'),
        [],
        nil
      ),
      NavigationItem.new(
        'Records',
        Rails.application.routes.url_helpers.records_path,
        'file-text',
        is_active?('records'),
        build_records_submenu,
        nil
      ),
      NavigationItem.new(
        'Software',
        Rails.application.routes.url_helpers.softwares_path,
        'package',
        is_active?('softwares'),
        [],
        nil
      ),
      NavigationItem.new(
        'Tags',
        Rails.application.routes.url_helpers.tags_path,
        'tag',
        is_active?('tags'),
        [],
        nil
      )
    ]
  end

  # Builds user account navigation menu
  # Displays only if user is authenticated
  def user_navigation
    return [] unless @current_user

    [
      NavigationItem.new(
        @current_user.full_name,
        Rails.application.routes.url_helpers.edit_user_registration_path,
        'user',
        is_active?('user_account'),
        build_user_submenu,
        nil
      )
    ]
  end

  # Builds records submenu with nested navigation
  # Demonstrates hierarchical navigation using framework routes
  def build_records_submenu
    [
      NavigationItem.new(
        'All Records',
        Rails.application.routes.url_helpers.records_path,
        'list',
        is_active?('records', 'index'),
        [],
        nil
      ),
      NavigationItem.new(
        'Create New',
        Rails.application.routes.url_helpers.new_record_path,
        'plus',
        is_active?('records', 'new'),
        [],
        nil
      ),
      NavigationItem.new(
        'My Records',
        Rails.application.routes.url_helpers.records_path(filter: 'my'),
        'star',
        is_active?('records', 'my'),
        [],
        nil
      )
    ]
  end

  # Builds user account submenu
  def build_user_submenu
    [
      NavigationItem.new(
        'Profile Settings',
        Rails.application.routes.url_helpers.edit_user_registration_path,
        'settings',
        is_active?('user_settings'),
        [],
        nil
      ),
      NavigationItem.new(
        'Sign Out',
        Rails.application.routes.url_helpers.destroy_user_session_path,
        'log-out',
        false,
        [],
        nil
      )
    ]
  end

  # Builds breadcrumb navigation for current page
  # Uses Rails routing to determine breadcrumb trail
  def breadcrumbs
    case @current_request&.path
    when /^\/records\/\d+/
      # Record detail page breadcrumb
      record = determine_record_from_path
      [
        build_breadcrumb_item('Home', root_path, 'home'),
        build_breadcrumb_item('Records', records_path, 'file-text'),
        build_breadcrumb_item(record&.title || 'Record', @current_path, 'document', true)
      ]
    when /^\/records$/
      # Records list breadcrumb
      [
        build_breadcrumb_item('Home', root_path, 'home'),
        build_breadcrumb_item('Records', @current_path, 'file-text', true)
      ]
    when /^\/records\/\d+\/edit/
      # Record edit page breadcrumb
      record = determine_record_from_path
      [
        build_breadcrumb_item('Home', root_path, 'home'),
        build_breadcrumb_item('Records', records_path, 'file-text'),
        build_breadcrumb_item(record&.title || 'Record', record_path(record), 'document'),
        build_breadcrumb_item('Edit', @current_path, 'edit', true)
      ]
    when /^\/softwares/
      [
        build_breadcrumb_item('Home', root_path, 'home'),
        build_breadcrumb_item('Software', @current_path, 'package', true)
      ]
    when /^\/tags/
      [
        build_breadcrumb_item('Home', root_path, 'home'),
        build_breadcrumb_item('Tags', @current_path, 'tag', true)
      ]
    else
      # Default breadcrumb for unknown routes
      [
        build_breadcrumb_item('Home', root_path, 'home', is_root?)
      ]
    end
  end

  # Builds a single breadcrumb item
  def build_breadcrumb_item(label, path, icon = nil, is_current = false)
    {
      label: label,
      path: path,
      icon: icon,
      current: is_current
    }
  end

  # Determines if current request matches given route name
  # Uses Rails routing introspection for framework-based route matching
  def is_active?(controller, action = nil)
    current_controller = @current_request&.path_parameters&.dig(:controller)
    current_action = @current_request&.path_parameters&.dig(:action)

    if action.nil?
      current_controller&.start_with?(controller)
    else
      current_controller == controller && current_action == action
    end
  end

  # Checks if current page is root/home
  def is_root?
    @current_path == '/'
  end

  # Generates navigation links for a resource
  # Framework-based resource routing helper
  def resource_navigation(resource_name, resource_id = nil)
    url_helpers = Rails.application.routes.url_helpers

    if resource_id
      {
        show: url_helpers.send("#{resource_name}_path", resource_id),
        edit: url_helpers.send("edit_#{resource_name}_path", resource_id),
        delete: url_helpers.send("#{resource_name}_path", resource_id)
      }
    else
      {
        index: url_helpers.send("#{resource_name.pluralize}_path"),
        new: url_helpers.send("new_#{resource_name}_path")
      }
    end
  end

  # Builds filter/category navigation
  # Useful for sidebar navigation with categories
  def category_navigation(categories)
    categories.map do |category|
      category_path = Rails.application.routes.url_helpers.records_path(category: category[:id])
      
      NavigationItem.new(
        category[:name],
        category_path,
        category[:icon],
        is_active_category?(category[:id]),
        category[:subcategories] || [],
        category[:count]
      )
    end
  end

  # Checks if a specific category is active
  def is_active_category?(category_id)
    @current_request&.query_parameters&.dig('category') == category_id.to_s
  end

  # Generates pagination navigation links
  # Framework-based pagination helper
  def pagination_navigation(current_page, total_pages, resource_name)
    pagination = {
      current_page: current_page,
      total_pages: total_pages,
      has_previous: current_page > 1,
      has_next: current_page < total_pages
    }

    if pagination[:has_previous]
      pagination[:previous_link] = Rails.application.routes.url_helpers.send(
        "#{resource_name.pluralize}_path",
        page: current_page - 1
      )
    end

    if pagination[:has_next]
      pagination[:next_link] = Rails.application.routes.url_helpers.send(
        "#{resource_name.pluralize}_path",
        page: current_page + 1
      )
    end

    pagination
  end

  # Builds nested navigation from a tree structure
  # Demonstrates hierarchical navigation handling
  def nested_navigation(items, current_level = 0, max_depth = 3)
    return [] if current_level >= max_depth

    items.map do |item|
      NavigationItem.new(
        item[:label],
        item[:path],
        item[:icon],
        item[:active] || false,
        nested_navigation(item[:children] || [], current_level + 1, max_depth),
        item[:badge]
      )
    end
  end

  # Generates mobile hamburger menu navigation
  # Simplified navigation for mobile viewports using Rails helpers
  def mobile_navigation
    {
      primary: main_navigation,
      secondary: user_navigation,
      footer_links: [
        { label: 'About', path: Rails.application.routes.url_helpers.root_path },
        { label: 'Help', path: '#' },
        { label: 'Settings', path: Rails.application.routes.url_helpers.edit_user_registration_path }
      ]
    }
  end

  # Determines navigation visibility based on user permissions
  # Framework integration with authorization logic
  def authorized_navigation(user)
    nav = main_navigation

    # Filter navigation based on user roles/permissions
    nav.select do |item|
      is_authorized?(user, item.label)
    end
  end

  # Checks if user is authorized to see navigation item
  def is_authorized?(user, item_label)
    return true unless user.nil?

    # Public navigation items visible to anonymous users
    public_items = ['Dashboard']
    public_items.include?(item_label)
  end

  private

  # Determines record from URL path
  def determine_record_from_path
    match = @current_path.match(/\/records\/(\d+)/)
    Record.find(match[1]) if match
  rescue
    nil
  end

  # Helper methods for Rails URL generation
  def root_path
    Rails.application.routes.url_helpers.root_path
  end

  def records_path(params = {})
    Rails.application.routes.url_helpers.records_path(params)
  end

  def record_path(record)
    Rails.application.routes.url_helpers.record_path(record)
  end

  def softwares_path
    Rails.application.routes.url_helpers.softwares_path
  end

  def tags_path
    Rails.application.routes.url_helpers.tags_path
  end
end
