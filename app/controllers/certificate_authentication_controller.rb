class CertificateAuthenticationController < ApplicationController

  layout :determine_layout
  def determine_layout
    if request.xhr?
      'modal'
    else
      'application'
    end
  end

  def login
    certificate = request.headers['SSL_CLIENT_CERT']

    @cert = Mconf::SSLClientCert.new(certificate)
    @user = @cert.user

    if @user.present?
      sign_in :user, @user

      respond_to do |format|
        format.json { render json: { result: true, redirect_to: my_home_path }, status: 200 }
      end
    else
      error = @cert.error || 'unknown'
      msg = I18n.t("certificate_authentication.error.#{error}")

      respond_to do |format|
        format.json { render json: { result: false, error: msg }, status: 200 }
      end
    end
  end

  # Serves the error modal
  def error
  end

  def pending
    # don't show it unless user logged via certificate
    # referers = [login_url, root_url, certificate_login_path]

    if user_signed_in?
      redirect_to root_path
    end
  end

end
