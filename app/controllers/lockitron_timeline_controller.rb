class LockitronTimelineController < ApplicationController
  def index
  end

  def insert_card

  	credentials = User.get_credentials(session[:user_id])

  	data = {
   		:client_id => Rails.application.secrets.glass_client_id,
   		:client_secret => Rails.application.secrets.glass_client_secret,
   		:refresh_token => credentials[:refresh_token],
   		:grant_type => "refresh_token"
		}

  	@response = ActiveSupport::JSON.decode(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
  	if @response["access_token"].present?
    	credentials[:access_token] = @response["access_token"]

			puts 'Creating client for insert'
    	@client = Google::APIClient.new
   		hash = { :access_token => credentials[:access_token], :refresh_token => credentials[:refresh_token] }
    	authorization = Signet::OAuth2::Client.new(hash)
    	@client.authorization = authorization

    	@mirror = @client.discovered_api('mirror', 'v1')

			# Delete any existing subscription
			result_subscription = @client.execute(
  			:api_method => @mirror.subscriptions.delete,
  			:parameters => { 'id' => 'timeline' },
  			:authorization => authorization)    	

    	insert_subscription( {
      	"kind" => "mirror#subscription",
      	"collection" => "timeline",
      	"userToken" => session[:user_id],
      	"verifyToken" => "monkey",
				"operation" => ["UPDATE"],
				"callbackUrl" => Rails.application.secrets.callbackUrl + '/update_card'
			})

    	insert_timeline_item( {
      	text: "Lockitron",
      	notification: { level: 'DEFAULT' },
      	sourceItemId: '1001',
      	menuItems: [
        	{ 
						action: 'CUSTOM',
						id: 'Lockitron-Timeline-Card-Items',
						values: [
							{ state: "DEFAULT",
								displayName: "Update",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "PENDING",
								displayName: "Updating..",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "CONFIRMED",
								displayName: "Updated",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							}
						]
					},
        	{ action: 'DELETE' },
					{ action: 'TOGGLE_PINNED' } ]
      	}
     
    	if (@result)
      	redirect_to(root_path, :notice => "All Timelines inserted")
    	else
      	redirect_to(root_path, :alert => "Timelines failed to insert. Please try again.")
    	end
    
  		else
    		Rails.logger.debug "No access token"
  	end
	end

  def update_card

		credentials = User.get_credentials(params[:userToken])
    timelineID = params[:itemId]

  	data = {
   		:client_id => Rails.application.secrets.glass_client_id,
   		:client_secret => Rails.application.secrets.glass_client_secret,
   		:refresh_token => credentials[:refresh_token],
   		:grant_type => "refresh_token"
		}

  	@response = ActiveSupport::JSON.decode(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
  	if @response["access_token"].present?
    	credentials[:access_token] = @response["access_token"]

    	@client = Google::APIClient.new
			hash = { :access_token => credentials[:access_token], :refresh_token => credentials[:refresh_token] }   	
			authorization = Signet::OAuth2::Client.new(hash)
    	@client.authorization = authorization

			puts 'Mirror creating..'
    	@mirror = @client.discovered_api('mirror', 'v1')
			puts 'Mirror created'
    
    	update_timeline_item( {
      	text: "Lockitron",      	
				notification: { level: 'DEFAULT' },
      	sourceItemId: '1001',
      	menuItems: [
        	{ 
						action: 'CUSTOM',
						id: 'Lockitron-Timeline-Card-Items',
						values: [
							{ state: "DEFAULT",
								displayName: "Update",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "PENDING",
								displayName: "Updating..",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "CONFIRMED",
								displayName: "Updated",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							}
						]
					},
        	{ action: 'DELETE' },
					{ action: 'TOGGLE_PINNED' } ]
      	},
				timelineID
				)

  	end
  end

	def insert_timeline_item(timeline_item)
 		method = @mirror.timeline.insert

		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item
 		).data

 	end

  def update_timeline_item(timeline_item, timelineID)
		method = @mirror.timeline.update

		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

		parameters = { 'id' => timelineID }

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item
 		).data

	end

	def insert_subscription(timeline_item, attachment_path = nil, content_type = nil)
 		method = @mirror.subscriptions.insert

 		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item
 		).data
 	end
end
