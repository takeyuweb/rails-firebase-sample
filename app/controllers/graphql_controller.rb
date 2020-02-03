class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  protect_from_forgery with: :null_session
  before_action :authenticate

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    result = MyAppSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { error: { message: e.message, backtrace: e.backtrace }, data: {} }, status: 500
  end

  # Firebase IDトークンの検証
  def authenticate
    authenticate_token || render_unauthorized
  end

  CIRTIFICATE_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  FIREBASE_PROJECT_ID = ENV['FIREBASE_PROJECT_ID']
  EXP_LEEWAY = 30.seconds

  def certificates
    cached = Rails.cache.read(CIRTIFICATE_URL)
    return cached if cached.present?

    uri = URI.parse(CIRTIFICATE_URL)
    resp = Net::HTTP.get_response(uri)
    body = JSON.parse(resp.body)
    expires_at = Time.zone.parse(resp.header['expires'])
    Rails.cache.write(CIRTIFICATE_URL, body, expires_in: expires_at - Time.current)

    body
  end

  def authenticate_token
    # Reactアプリで取得した IdToken を Cookie に入れておき、ヘッダーに入れ込むワークアラウンド
    request.headers['Authorization'] = "Bearer #{cookies["_graphql_token"]}" if Rails.env.development? && cookies["_graphql_token"].present?

    authenticate_with_http_token do |id_token, options|
      # https://firebase.google.com/docs/auth/admin/verify-id-tokens?hl=ja
      _, decoded_token_header = JWT.decode(id_token, nil, false)

      certificate = certificates.fetch(decoded_token_header["kid"])
      public_key = OpenSSL::X509::Certificate.new(certificate).public_key
      decoded_token_payload, _ = JWT.decode(
        id_token,
        public_key,
        true,
        exp_leeway: EXP_LEEWAY,   # 有効期限の検証をするが、ゆるめに。 EXP_LEEWAY 秒は大目に見る。
        verify_iat: true,         # 発行時の検証をする
        aud: FIREBASE_PROJECT_ID,
        verify_aud: true,         # 対象の検証をする
        iss: "https://securetoken.google.com/#{FIREBASE_PROJECT_ID}",
        verify_iss: true,         # 発行元の検証をする
        verify_sub: true,         # 件名の存在を検証する
        algorithm: decoded_token_header["alg"]
      )
      raise 'Invalid auth_time' unless Time.zone.at(decoded_token_payload['auth_time']).past?

      # decoded_token_payload = {
      #   "name"=>"Takeuchi Yuichi",
      #   "picture"=>"https://lh3.googleusercontent.com/a-/AAuE7mAZU7Rh7lIFStzfWGe3tC24qDIX4UIoEWR8426flA",
      #   "iss"=>"https://securetoken.google.com/rails-firebase-sample",
      #   "aud"=>"rails-firebase-sample",
      #   "auth_time"=>1580712233,
      #   "user_id"=>"Qgk3sd1HgoPLVbSy8uXAWnRmWmx1",
      #   "sub"=>"Qgk3sd1HgoPLVbSy8uXAWnRmWmx1",
      #   "iat"=>1580712233,
      #   "exp"=>1580715833,
      #   "email"=>"yuichi.takeuchi@takeyuweb.co.jp",
      #   "email_verified"=>true,
      #   "firebase"=>{
      #     "identities"=>{
      #       "google.com"=>["100008179958237311525"],
      #       "email"=>["yuichi.takeuchi@takeyuweb.co.jp"]
      #     },
      #     "sign_in_provider"=>"google.com"
      #   }
      # }

      true
    end
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  def render_unauthorized
    render json: { error: { message: 'token invalid' }, data: {} }, status: :unauthorized
  end
end
