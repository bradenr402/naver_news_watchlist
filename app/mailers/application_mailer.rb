class ApplicationMailer < ActionMailer::Base
  default from: "Naver Watchlist <#{Rails.application.credentials.dig(:smtp, :user_name)}>"
  layout false
end
