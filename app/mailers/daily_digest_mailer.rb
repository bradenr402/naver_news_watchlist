class DailyDigestMailer < ApplicationMailer
  def digest_email(recipient_email, sections)
    @sections = sections
    @digest_date = Time.zone.today.strftime("%Y-%m-%d")
    @title = "Naver News Watchlist Digest — #{@digest_date}"

    mail(
      to: recipient_email,
      subject: @title,
      charset: "UTF-8", # ensures Korean text is rendered correctly
    )
  end
end
