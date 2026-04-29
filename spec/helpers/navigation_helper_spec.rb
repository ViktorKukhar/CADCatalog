# frozen_string_literal: true

require 'rails_helper'

describe NavigationHelper do
  let(:user) { create(:user) }
  let(:request_mock) do
    instance_double(
      'ActionDispatch::Request',
      path: '/records',
      url: 'http://example.com/records',
      path_parameters: { controller: 'records', action: 'index' },
      query_parameters: {}
    )
  end

  describe '#render_main_navigation' do
    it 'renders main navigation HTML' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      expect(output).to include('nav')
      expect(output).to include('main-navigation')
    end

    it 'renders navigation items as list' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      expect(output).to include('nav-item')
      expect(output).to include('nav-link')
    end

    it 'marks active navigation items' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      expect(output).to include('active')
    end
  end

  describe '#render_breadcrumbs' do
    it 'renders breadcrumb navigation structure' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_breadcrumbs

      expect(output).to include('breadcrumb')
      expect(output).to include('ol')
    end

    it 'renders breadcrumb items' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_breadcrumbs

      expect(output).to include('Home')
    end

    it 'marks current breadcrumb as active' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_breadcrumbs

      expect(output).to include('active')
    end

    it 'provides accessible breadcrumb navigation' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_breadcrumbs

      expect(output).to include('aria-label')
    end
  end

  describe '#render_pagination' do
    it 'renders pagination navigation' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_pagination(1, 5, 'record')

      expect(output).to include('pagination')
      expect(output).to include('nav')
    end

    it 'renders page numbers' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_pagination(1, 5, 'record')

      expect(output).to include('page-item')
    end

    it 'marks current page as active' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_pagination(3, 5, 'record')

      expect(output).to include('page-current')
    end

    it 'includes next/previous links' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_pagination(2, 5, 'record')

      expect(output).to include('Previous')
      expect(output).to include('Next')
    end
  end

  describe '#render_tab_navigation' do
    let(:tabs) do
      [
        { id: 'all', label: 'All Records', path: '/records' },
        { id: 'mine', label: 'My Records', path: '/records?filter=mine' }
      ]
    end

    it 'renders tab navigation structure' do
      output = helper.render_tab_navigation(tabs)

      expect(output).to include('tab-navigation')
      expect(output).to include('tabs')
    end

    it 'renders tab items' do
      output = helper.render_tab_navigation(tabs)

      expect(output).to include('All Records')
      expect(output).to include('My Records')
    end

    it 'marks active tab' do
      output = helper.render_tab_navigation(tabs, 'all')

      expect(output).to include('active')
    end

    it 'provides accessible tab structure' do
      output = helper.render_tab_navigation(tabs)

      expect(output).to include('role="tablist"')
      expect(output).to include('role="tab"')
    end
  end

  describe '#render_category_navigation' do
    let(:categories) do
      [
        { id: 1, name: 'Mechanical', icon: 'gear', count: 5 },
        { id: 2, name: 'Electrical', icon: 'zap', count: 3 }
      ]
    end

    it 'renders category sidebar navigation' do
      output = helper.render_category_navigation(categories)

      expect(output).to include('category-navigation')
    end

    it 'renders category items with counts' do
      output = helper.render_category_navigation(categories)

      expect(output).to include('Mechanical')
      expect(output).to include('badge')
    end

    it 'renders category links' do
      output = helper.render_category_navigation(categories)

      expect(output).to include('category-link')
    end
  end

  describe '#render_user_navigation' do
    it 'returns empty string when no user' do
      helper.stub(:current_user).and_return(nil)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_user_navigation

      expect(output).to eq('')
    end

    it 'renders user navigation when authenticated' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_user_navigation

      expect(output).not_to eq('')
      expect(output).to include('user-navigation')
    end

    it 'includes user name in navigation' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_user_navigation

      expect(output).to include(user.full_name)
    end
  end

  describe '#render_mobile_menu' do
    it 'renders mobile navigation structure' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_mobile_menu

      expect(output).to include('mobile-menu')
    end

    it 'includes primary and secondary menu sections' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_mobile_menu

      expect(output).to include('mobile-menu-section')
    end

    it 'includes footer links in mobile menu' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_mobile_menu

      expect(output).to include('mobile-menu-footer')
      expect(output).to include('Settings')
    end
  end

  describe '#render_page_indicator' do
    it 'renders page title indicator' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_page_indicator

      expect(output).to include('page-indicator')
      expect(output).to include('h1')
    end

    it 'displays current page name' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_page_indicator

      expect(output).to include('Records')
    end
  end

  describe '#render_resource_actions' do
    let(:record) { create(:record, user: user) }

    it 'renders resource action buttons' do
      output = helper.render_resource_actions(record)

      expect(output).to include('resource-actions')
    end

    it 'includes view, edit, and delete actions' do
      output = helper.render_resource_actions(record)

      expect(output).to include('View')
      expect(output).to include('Edit')
      expect(output).to include('Delete')
    end

    it 'generates proper polymorphic routes' do
      output = helper.render_resource_actions(record)

      expect(output).to include('btn')
    end
  end

  describe '#render_authorized_navigation' do
    it 'filters navigation for authorized user' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_authorized_navigation

      expect(output).to include('authorized-navigation')
    end

    it 'includes public navigation items' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_authorized_navigation

      expect(output).to include('Dashboard')
    end
  end

  describe 'Framework integration' do
    it 'uses Rails content_tag helpers' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      expect(output).to include('<nav')
      expect(output).to include('<ul')
    end

    it 'uses Rails link_to for route generation' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_breadcrumbs

      expect(output).to include('<a')
    end

    it 'uses polymorphic helpers for resources' do
      record = create(:record, user: user)
      output = helper.render_resource_actions(record)

      expect(output).to include('href')
    end
  end

  describe 'HTML safety' do
    it 'returns HTML safe content' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      expect(output).to be_html_safe
    end

    it 'properly escapes content in navigation' do
      helper.stub(:current_user).and_return(user)
      helper.stub(:request).and_return(request_mock)

      output = helper.render_main_navigation

      # Should not include raw script tags
      expect(output).not_to include('<script>')
    end
  end
end
