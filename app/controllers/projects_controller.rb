class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:id])
    @range = range
    @period = period
  end

  def index
    @scope = Project.with_repository.active

    if params[:keyword].present?
      @scope = @scope.keyword(params[:keyword])
    end

    if params[:owner].present?
      @scope = @scope.owner(params[:owner])
    end

    if params[:language].present?
      @scope = @scope.language(params[:language])
    end

    if params[:sort]
      @scope = @scope.order("#{params[:sort]} #{params[:order]}")
    else
      @scope = @scope.order_by_stars
    end

    @pagy, @projects = pagy(@scope)
  end

  def lookup
    @project = Project.find_by(url: params[:url].downcase)
    if @project.nil?
      @project = Project.create(url: params[:url].downcase)
      @project.sync_async
    end
    redirect_to @project
  end

  def packages
    @project = Project.find(params[:id])
    @pagy, @packages = pagy(@project.packages.active.order_by_rankings)
  end

  def commits
    @project = Project.find(params[:id])
    @pagy, @commits = pagy(@project.commits.order('timestamp DESC'))
  end

  def releases
    @project = Project.find(params[:id])
    @pagy, @releases = pagy(@project.tags.order('published_at DESC'))
  end

  def issues
    @project = Project.find(params[:id])
    @pagy, @issues = pagy(@project.issues.order('created_at DESC'))
  end

  def advisories
    @project = Project.find(params[:id])
    @pagy, @advisories = pagy(@project.advisories.order('published_at DESC'))
  end
end