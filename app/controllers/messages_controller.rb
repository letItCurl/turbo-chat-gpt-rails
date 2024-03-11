class MessagesController < ApplicationController

  # POST /:id/messages or /messages.json
  def create
    @chat = Chat.find(params[:id])
    @message = @chat.messages.new(message_params)

    respond_to do |format|
      if @message.save
        format.html { redirect_to message_url(@message), notice: "Message was successfully created." }
        format.turbo_stream
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:chat_id, :content, :role)
    end
end
