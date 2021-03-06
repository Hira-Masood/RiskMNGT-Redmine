#  Copyright (C) 2009 Isotrol S.A.
#  Contribution: Nicolas Bertet, Chief project. José Cano Ruiz, Developer.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 3 of the License, or
#  any later version.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
#  Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program. If not, see <http://www.gnu.org/licenses/>, or contact
#  us at Isotrol S.A. Edificio BLUENET. Avda. Isaac Newton nº 3, 4ª planta.
#  Parque Tecnológico Cartuja ´93, 41092 Sevilla.
#
#  *************************************************************************
#
#  Licensed under the EUPL, Version 1.1 or – as soon they will be approved by
#  the European Commission – subsequent versions of the EUPL (the "Licence");
#  you may not use this work except in compliance with the Licence.
#
#  You may obtain a copy of the Licence at: http://ec.europa.eu/idabc/7330l5
#  or contact us at Isotrol S.A. Edificio BLUENET. Avda. Isaac Newton nº 3,
#  4ª planta. Parque Tecnológico Cartuja ´93, 41092 Sevilla
#
#  Unless required by applicable law or agreed to in writing, software distributed
#  under the Licence is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#  CONDITIONS OF ANY KIND, either express or implied.
#
#  See the Licence for the specific language governing permissions and limitations
#  under the Licence.

#This class represents the super class of all the controllers on the risk plugin
class BaseRiskApplicationController < ApplicationController

  #Authorize to access controllers which don't depends on a specific project
  #* @param1= ctrl: default params[:controller]
  #* @param2= action: default params[:action]
  #* @returns= true if the user is allowed, otherwise redirect to _deny_access_ method
  protected
  def authorize_global(ctrl = params[:controller], action = params[:action])
    action = {:controller => ctrl, :action => action}
    allowed = User.current.allowed_to?(action , nil , :global => true)
    allowed ? true : deny_access
  end

  #Set the _project_ variable depending on the _project_id_ parameter
  #It renders to _render_404 when the _project_ cannot be found
  protected
  def find_project
    @project = Project.find( params[:project_id] )
    rescue ActiveRecord::RecordNotFound
      render_404
  end

  protected
  #If the request is a post and _params_ is not null, it set up the attributes of the _record_ to _params_,
  #if _record_ has project as property, it set _project_ to the mentioned property and on the same way set the property author of _record_ with current user.
  #After the configuration process and only when the first condition is satisfied, _record_ is saved.
  #Redirects to index when _record_ was sucessfully saved.
  #* @param1= record: active record object to be saved
  #* @param2= params: value of the attributes of _record_
  #* @param3= notice_successful: message to be shown when _record_ was sucessfully saved.
  #* @param4= project: variable to be assigned to _record_ and being used on the redirection
  def edit( record ,  params , notice_successful, project = nil )
    if request.post? && !params.nil?
       record.attributes = params
       record.project =  project if record.respond_to? :project
       record.author = User.current if record.respond_to? :author


       if record.save
          flash[:notice] = notice_successful

         if project.nil?
           redirect_to :action => 'index'
            else
           redirect_to :action => 'index' , :project_id => project
         end

         return
       end
    end

  end

  #Add a issue selected via _issue_id to the _obj_, when _obj_ has no associated the specific issue on its issues list
  #Redirect to issues_index view
  protected
  def issues_new( issue_id, obj, project )

    # it could return error messages
    if Issue.exists?( issue_id ) &&
       !obj.issues.exists?( issue_id )

      obj.issues << Issue.find( issue_id )
      obj.save
    end

    # it could be refactored
    redirect_to :action => 'issues_index', :id => obj , :project_id => project
  end

  #Delete a issue selected via _issue_id_ from the issue list of _obj_
  #Redirect to issues_index view
  protected
  def issues_delete( issue_id, obj, project )
    begin
      issue = Issue.find( issue_id )
    rescue ActiveRecord::RecordNotFound
      render_404
      return
    end

    obj.issues.delete( issue  ) #if @project_risk.issues.exists?( params[:issue_id]  )

    # it could be refactored
    redirect_to :action => 'issues_index', :id =>obj , :project_id => project
  end

  #Find risks, risk_count, risk_pages depending on the parameters
  protected
  def risks_search

    conditionStm = risk_query_condition
    limit = per_page_option

    @risk_count = Risk.count(:conditions => conditionStm)
    @risk_pages = Paginator.new self, @risk_count, limit, params['page']
    @risks = Risk.find :all, :conditions => conditionStm, :limit  => limit, :offset => @risk_pages.current.offset
  end

  #Creates the query condition to be used on a risk search
  protected
  def risk_query_condition
    # refactorable
    if has_value_params( @risk_status ) && has_value_params( @risk_category_id )
      ["status=? AND risk_category_id=?", @risk_status , @risk_category_id ]
    elsif has_value_params( @risk_status )
      ["status=? ", @risk_status ]
    elsif has_value_params( @risk_category_id )
      ["risk_category_id=?", @risk_category_id ]
    else
      nil
    end
  end

  #Returns true if an integer identifier "id" of a collection item is equal to id, otherwise false
  protected
  def exist(collection, id)
    for item in collection
      return true if item.id.to_i == id.to_i
    end
    return false
  end

  #Returns true if _val_ is not null and blank, otherwise false
  private
  def has_value_params(val)
    !val.nil? && !val.blank?
  end
end
