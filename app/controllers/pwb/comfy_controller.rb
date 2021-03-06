require_dependency 'pwb/application_controller'

module Pwb
  # based on
  # comfortable-mexican-sofa/app/controllers/comfy/cms/content_controller.rb
  class ComfyController < ApplicationController
    # Comfy::Cms::BaseController

    # Authentication module must have `authenticate` method
    include ComfortableMexicanSofa.config.public_auth.to_s.constantize

    # Authorization module must have `authorize` method
    include ComfortableMexicanSofa.config.public_authorization.to_s.constantize

    before_action :load_cms_site
    # before_action :load_fixtures
    # before_action :load_cms_page
    #   :authenticate,
    #   :authorize,
    #   :only => :show

    rescue_from ActiveRecord::RecordNotFound, with: :page_not_found

    def show
      @cms_pages = []

      begin
        cms_page_container = Pwb::CmsPageContainer.find(params[:page_slug])
        cms_page_container.cmsPartsList.each do |cms_part|
          @cms_page = Comfy::Cms::Page.where({label: cms_part["label"], slug: I18n.locale}).first
          # @cms_site.pages.published.find_by_full_path!("/about-us/services")
          @cms_pages.push @cms_page if @cms_page
        end
      rescue ActiveHash::RecordNotFound
      end

      @content_area_cols = Content.where(tag: 'content-area-cols').order('sort_order')

      render "/pwb/sections/cms"

      # cms_page_path =  "/#{params[:page_slug]}-page"
      # https://github.com/comfy/comfortable-mexican-sofa/wiki/View-rendering
      # below makes use of Comfy view rendering:

      # return render :cms_page => cms_page_path, :layout => "pwb/application", :cms_blocks => {
      #   :jumbotron => 'Content About Events'
      #   # :column_b => { :template => '/events/index' },
      #   # :column_c => { :partial  => '/events/calendar' }
      # }
      # return render @cms_page.content_cache
      # , layout: "application"
    end

    def render_sitemap
      render
    end

    protected

    def load_cms_site
      # TODO: - load diff sites depending on locale//
      @cms_site = ::Comfy::Cms::Site.find_by_locale :es
      # (::Comfy::Cms::Site.find_by_locale I18n.locale) || (::Comfy::Cms::Site.find_by_locale :en)
    end

    # def render_page(status = 200)
    #   # below will ren
    #   if @cms_layout = @cms_page.layout
    #     # app_layout = (@cms_layout.app_layout.blank? || request.xhr?) ? false : @cms_layout.app_layout
    #     app_layout = "application"
    #     render  :inline       => @cms_page.content_cache,
    #       :layout       => app_layout,
    #       :status       => status,
    #       :content_type => mime_type
    #   else
    #     render :plain => I18n.t('comfy.cms.content.layout_not_found'), :status => 404
    #   end
    # end

    # it's possible to control mimetype of a page by creating a `mime_type` field
    def mime_type
      mime_block = @cms_page.blocks.find_by_identifier(:mime_type)
      mime_block && mime_block.content || 'text/html'
    end

    def load_fixtures
      return unless ComfortableMexicanSofa.config.enable_fixtures
      ComfortableMexicanSofa::Fixture::Importer.new(@cms_site.identifier).import!
    end

    def load_cms_page(_page_key)
      @cms_page = @cms_site.pages.published.find_by_full_path!("/[:cms_path]")
    end

    def page_not_found
      @cms_page = @cms_site.pages.published.find_by_full_path!('/404')

      respond_to do |format|
        format.html { render_page(404) }
      end
    rescue ActiveRecord::RecordNotFound
      raise ActionController::RoutingError, "Page Not Found at: \"#{params[:cms_path]}\""
    end
  end
end
