# NavigationHelper - Rails View Helper for Navigation
# Provides view-layer methods to render navigation using the NavigationBuilder service
# Implements uniform navigation rendering across all views

module NavigationHelper
  # Renders main application navigation menu
  # Uses Rails link_to helpers for route generation
  def render_main_navigation
    builder = NavigationBuilder.new(current_user, request)
    menu_items = builder.main_navigation

    content_tag :nav, class: 'main-navigation' do
      content_tag :ul, class: 'nav-menu' do
        menu_items.map { |item| render_nav_item(item) }.join.html_safe
      end
    end
  end

  # Renders a single navigation item with support for submenus
  def render_nav_item(item)
    classes = ['nav-item']
    classes << 'active' if item.active?
    classes << 'has-children' if item.children.any?

    content_tag :li, class: classes.join(' ') do
      link = link_to(item.label, item.path, class: 'nav-link')
      
      if item.children.any?
        submenu = content_tag :ul, class: 'nav-submenu' do
          item.children.map { |child| render_nav_item(child) }.join.html_safe
        end
        link + submenu
      else
        link
      end
    end
  end

  # Renders user account navigation dropdown
  def render_user_navigation
    builder = NavigationBuilder.new(current_user, request)
    user_items = builder.user_navigation

    return '' if user_items.empty?

    content_tag :div, class: 'user-navigation' do
      user_items.map { |item| render_nav_item(item) }.join.html_safe
    end
  end

  # Renders breadcrumb navigation trail
  # Uses Rails link_to for safe URL generation
  def render_breadcrumbs
    builder = NavigationBuilder.new(current_user, request)
    breadcrumbs = builder.breadcrumbs

    content_tag :nav, class: 'breadcrumb-nav', 'aria-label': 'breadcrumb' do
      content_tag :ol, class: 'breadcrumb' do
        breadcrumbs.map do |crumb|
          content_tag :li, class: 'breadcrumb-item' do
            if crumb[:current]
              content_tag :span, crumb[:label], class: 'active'
            else
              link_to(crumb[:label], crumb[:path])
            end
          end
        end.join.html_safe
      end
    end
  end

  # Renders category/filter sidebar navigation
  # Demonstrates isolated navigation logic using builder pattern
  def render_category_navigation(categories)
    builder = NavigationBuilder.new(current_user, request)
    nav_items = builder.category_navigation(categories)

    content_tag :aside, class: 'category-navigation' do
      content_tag :h3, 'Categories' do
        content_tag :ul, class: 'category-list' do
          nav_items.map do |item|
            render_category_item(item)
          end.join.html_safe
        end
      end
    end
  end

  # Renders a category navigation item with badge support
  def render_category_item(item)
    classes = ['category-item']
    classes << 'active' if item.active?

    content_tag :li, class: classes.join(' ') do
      link = link_to(item.label, item.path, class: 'category-link')
      
      if item.badge
        badge = content_tag :span, item.badge, class: 'badge'
        link + badge
      else
        link
      end
    end
  end

  # Renders pagination navigation
  def render_pagination(current_page, total_pages, resource_name)
    builder = NavigationBuilder.new(current_user, request)
    pagination = builder.pagination_navigation(current_page, total_pages, resource_name)

    content_tag :nav, class: 'pagination-nav', 'aria-label': 'pagination' do
      items = []

      if pagination[:has_previous]
        items << content_tag(:li, link_to('← Previous', pagination[:previous_link], class: 'prev-link'))
      end

      # Page numbers
      (1..pagination[:total_pages]).each do |page|
        if page == current_page
          items << content_tag(:li, content_tag(:span, page, class: 'page-current'), class: 'page-item active')
        else
          path = Rails.application.routes.url_helpers.send("#{resource_name.pluralize}_path", page: page)
          items << content_tag(:li, link_to(page, path, class: 'page-link'), class: 'page-item')
        end
      end

      if pagination[:has_next]
        items << content_tag(:li, link_to('Next →', pagination[:next_link], class: 'next-link'))
      end

      content_tag :ul, items.join.html_safe
    end
  end

  # Renders mobile hamburger menu
  def render_mobile_menu
    builder = NavigationBuilder.new(current_user, request)
    mobile_nav = builder.mobile_navigation

    content_tag :div, class: 'mobile-menu' do
      [
        render_mobile_menu_section('Primary', mobile_nav[:primary]),
        render_mobile_menu_section('Account', mobile_nav[:secondary]),
        render_mobile_footer_links(mobile_nav[:footer_links])
      ].join.html_safe
    end
  end

  # Renders a section of mobile menu
  def render_mobile_menu_section(title, items)
    content_tag :section, class: 'mobile-menu-section' do
      content_tag :h3, title do
        content_tag :ul, class: 'mobile-menu-list' do
          items.map { |item| render_nav_item(item) }.join.html_safe
        end
      end
    end
  end

  # Renders mobile footer links
  def render_mobile_footer_links(links)
    content_tag :footer, class: 'mobile-menu-footer' do
      content_tag :ul, class: 'footer-links' do
        links.map do |link|
          content_tag :li, link_to(link[:label], link[:path])
        end.join.html_safe
      end
    end
  end

  # Renders active page indicator for current navigation state
  def render_page_indicator
    builder = NavigationBuilder.new(current_user, request)
    
    breadcrumbs = builder.breadcrumbs
    current_page = breadcrumbs.last

    content_tag :div, class: 'page-indicator' do
      content_tag :h1, current_page[:label]
    end
  end

  # Renders tab navigation for sub-sections
  # Useful for records, software sections with multiple views
  def render_tab_navigation(tabs, active_tab = nil)
    content_tag :nav, class: 'tab-navigation' do
      content_tag :ul, class: 'tabs', role: 'tablist' do
        tabs.map do |tab|
          is_active = active_tab == tab[:id]
          classes = ['tab-item']
          classes << 'active' if is_active

          content_tag :li, class: classes.join(' '), role: 'presentation' do
            link_to(tab[:label], tab[:path], class: 'tab-link', role: 'tab', 'aria-selected': is_active)
          end
        end.join.html_safe
      end
    end
  end

  # Renders resource action links (show, edit, delete)
  # Framework-based resource routing helpers
  def render_resource_actions(resource)
    content_tag :div, class: 'resource-actions' do
      [
        link_to('View', resource, class: 'btn btn-primary'),
        link_to('Edit', edit_polymorphic_path(resource), class: 'btn btn-secondary'),
        link_to('Delete', resource, method: :delete, data: { confirm: 'Are you sure?' }, class: 'btn btn-danger')
      ].join.html_safe
    end
  end

  # Renders authorized navigation based on current user
  # Integrates with Rails authorization system
  def render_authorized_navigation
    builder = NavigationBuilder.new(current_user, request)
    authorized_items = builder.authorized_navigation(current_user)

    content_tag :nav, class: 'authorized-navigation' do
      content_tag :ul, class: 'nav-menu' do
        authorized_items.map { |item| render_nav_item(item) }.join.html_safe
      end
    end
  end

  # Renders active navigation state indicator
  # Helps users understand current location in app
  def render_active_indicator
    builder = NavigationBuilder.new(current_user, request)
    
    content_tag :div, class: 'active-nav-indicator' do
      if builder.is_root?
        content_tag :span, 'Home', class: 'location'
      else
        content_tag :span, 'Current Page', class: 'location'
      end
    end
  end
end
