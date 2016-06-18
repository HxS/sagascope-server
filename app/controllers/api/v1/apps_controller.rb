class Api::V1::AppsController < ApplicationController
  include JSONError
  protect_from_forgery with: :null_session
  skip_before_filter :verify_authenticity_token


  def resources
    app_id = params["id"]
    app = App.find_by(id:app_id)
    if app == nil
      render_error "指定されたアプリが見つかりません"
    else
      characters = []
      markers = []
      advertisings = []
      app.companies.where(enabled:true).each{|c|
        characters.push c.character.attributes.select{|k,v| [:id, :name, :target_id, :updated_at].include? k.to_sym}
        markers.concat c.markers.where(enabled:true).pluck_to_hash(:id, :target_id, :updated_at)
        c.markers.each{|m|
          advertisings.concat m.advertisings.where(enabled:true).pluck_to_hash(:id, :image_url, :link_url, :updated_at)
        }
      }
      render json:{characters:characters, markers:markers, advertisings:advertisings}
    end
  end

  def relations
    app_id = params["id"]
    app = App.find_by(id:app_id)
    if app == nil
      render_error "指定されたアプリが見つかりません"
    else
      relations = []
      app.companies.where(enabled:true).each{|c|
        character_id = c.character.id
        c.markers.where(enabled:true).each{|m|
          advertisings = []
          advertisings.concat m.advertisings.where(enabled:true).pluck(:id)
          relations.push({marker_id:m.id, character_id: character_id, advertisings:advertisings})
        }
      }
      render json:relations
    end
  end

  def impressions
    app_id = params["id"]
    user = User.find_by(uuid:params["uuid"])
    unless user
      render_error "指定されたユーザが存在しません"
      return
    end
    save_params = {}
    save_params[:user_id] = user.try(:id)
    [:advertising_id, :latitude, :longitude].each{|k|
      save_params[k] = params[k].presence
    }
    save_params[:displayed_at] = Time.now

    unless Advertising.find_by(id:save_params[:advertising_id])
      render_error "指定された広告が存在しません"
      return
    end

    impl = Impression.create(save_params)
    if impl.invalid?
      render_error "パラメータが不足しています"
      return
    end
    render json:nil
  end

  def reaches
    app_id = params["id"]
    user = User.find_by(uuid:params["uuid"])
    unless user
      render_error "指定されたユーザが存在しません"
      return
    end
    save_params = {}
    save_params[:user_id] = user.try(:id)
    [:advertising_id, :latitude, :longitude].each{|k|
      save_params[k] = params[k].presence
    }
    save_params[:displayed_at] = Time.now
    unless Advertising.find_by(id:save_params[:advertising_id])
      render_error "指定された広告が存在しません"
      return
    end
    reach = Reach.create(save_params)
    if reach.invalid?
      render_error "パラメータが不足しています"
      return
    end
    render json:nil
  end
end
