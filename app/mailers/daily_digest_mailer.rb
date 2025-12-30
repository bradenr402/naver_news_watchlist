class DailyDigestMailer < ApplicationMailer
  def digest_email(recipient_email, sections)
    @sections = sections
    @digest_date = Time.zone.today.strftime("%F")
    @title = "Naver News Watchlist Digest — #{@digest_date}"

    mail(
      to: recipient_email,
      subject: @title,
      charset: "UTF-8", # ensures Korean text is rendered correctly
    )
  end

  def error_email(recipient_email, error_payload)
    @error_class = error_payload[:class]
    @error_message = error_payload[:message]
    @error_backtrace = Array(error_payload[:backtrace])

    @error_time = Time.zone.now.strftime("%F %R %Z")
    @title = "Naver News Watchlist Error — #{@error_time}"

    mail(
      to: recipient_email,
      subject: @title,
      charset: "UTF-8",
    )
  end
end
