class ApplicationMailer < ActionMailer::Base
  default from: "Naver News Watchlist <#{Rails.application.credentials.dig(:smtp, :user_name)}>"
  layout false
end
