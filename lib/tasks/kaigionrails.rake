namespace :kaigionrails do
  desc "Seed development data that mirrors the production Kaigi on Rails 2026 event"
  task seed: :environment do
    raise "Do not run this task in production!" if Rails.env.production?

    perform_deliveries_orig = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    pwd = "userpass"

    # --- Users -------------------------------------------------------------
    find_user = ->(name, email, admin: false) do
      User.where(email: email).first_or_create! do |u|
        u.name = name
        u.admin = admin
        u.password = pwd
        u.password_confirmation = pwd
        u.confirmed_at = Time.current
      end
    end

    admin     = find_user.call("Admin", "an@admin.com", admin: true)
    organizer = find_user.call("Event MC", "mc@seed.event")
    reviewer  = find_user.call("Reviewer", "review@seed.event")

    speakers = {
      yui:     find_user.call("佐藤 結衣", "yui@example.com"),
      kenta:   find_user.call("田中 健太", "kenta@example.com"),
      misaki:  find_user.call("鈴木 美咲", "misaki@example.com"),
      daichi:  find_user.call("高橋 大地", "daichi@example.com"),
      aoi:     find_user.call("伊藤 葵", "aoi@example.com"),
      ren:     find_user.call("渡辺 蓮", "ren@example.com"),
      hana:    find_user.call("山本 花", "hana@example.com"),
      sota:    find_user.call("中村 颯太", "sota@example.com"),
    }

    # --- Event (mirrors https://cfp.kaigionrails.org/events/2026/) ----------
    guidelines = <<~MARKDOWN
      日本語は英語のあとに続きます。

      ## Proposal guidelines

      Before you submit proposals, please confirm the following cautions.

      * Kaigi on Rails is a tech conference focused on Ruby on Rails.
      * If your topic is related to Rails or web development, it has a good chance of being selected. Topics that are solely about Ruby may have lower priority.
      * You can submit a proposal for either a 15-minute or 30 minute talk.
      * You can fill out the form in either Japanese or English.
      * Talks can be given in either Japanese or English.
      * Talks must be given in person at the venue.
      * Slides can be in either Japanese or English.
      * Please ensure that any images, figures, and quotations used in your slides do not infringe on any third-party rights.
      * The CFP is open until July 12, 2026.
      * There is no limit to the number of proposals you may submit. Submitting multiple proposals is welcome.
      * Prior experience as a speaker is not required. We welcome proposals from first time speakers.
      * Talks will be recorded and made publicly available after the event.
      * To submit a talk, you must agree to comply with the Anti-Harassment Policy.
        * [https://kaigionrails.org/2026/policies/](https://kaigionrails.org/2026/policies/)
      * Those who submit proposals will be able to purchase a conference ticket at a discounted price.
      * You may receive feedback on your proposal from the organizers, but this is not a guarantee that your proposal will be accepted.

      We would be happy if you could answer this survey as well.

      [https://forms.gle/mFSha6JfbfikYMdd9](https://forms.gle/mFSha6JfbfikYMdd9)

      ## CFPについて

      プロポーザルの提出に際し、以下の点について確認をお願いします。

      * Kaigi on RailsはRuby on Railsに関するテックカンファレンスです。
      * トピックはRailsやWeb開発に関わることであれば、選定される可能性はあります。Rubyに特化した話題については、優先度が下がるかもしれません。
      * トークの長さは15分か30分かを選んでいただきます。
      * フォームは日本語または英語で記述してください。
      * トークは日本語または英語で行ってください。
      * トークは、現地で行っていただきます。
      * スライドは日本語か英語で記述してください。英語での記述を推奨します。
      * スライドで使用する画像・図表・引用などは、権利上問題のないものをご使用ください。
      * CFPは2026年7月12日まで受け付けています。
      * プロポーザルの応募数に制限はございません。複数の応募をしていただくことも可能です。
      * プロポーザルの選定において、実務経験や登壇経験は問いません。
      * 発表は録画し、イベント終了後に公開する予定です。
      * トークを提出するにはアンチハラスメントポリシーを遵守することを承認していただく必要があります。
        * [https://kaigionrails.org/2026/policies/](https://kaigionrails.org/2026/policies/)
      * プロポーザルを提出していただいた方には、本編参加チケットを割引価格で購入していただくことができます。
      * 提出していただいたプロポーザルには、運営からフィードバックをさせていただくことがありますが、対応していただくと採択を保証するというものではありません。
    MARKDOWN

    event = Event.where(slug: "2026").first_or_create! do |e|
      e.name = "Kaigi on Rails 2026"
      e.contact_email = "info@kaigionrails.org"
      e.url = "https://kaigionrails.org/2026/"
      e.state = "open"
      e.closes_at = Time.utc(2026, 7, 12, 15, 0) # Jul 12, 2026 08:00am PDT
      e.start_date = Date.new(2026, 10, 16)
      e.end_date = Date.new(2026, 10, 17)
      e.guidelines = guidelines
    end

    # --- Session formats -----------------------------------------------------
    talk15 = event.public_session_formats.where(name: "15分トーク", duration: 15).first_or_create! do |f|
      f.description = "15分のトークです。"
    end
    talk30 = event.public_session_formats.where(name: "30分トーク", duration: 30).first_or_create! do |f|
      f.description = "30分のトークです。"
    end
    keynote_format = event.session_formats.where(name: "基調講演", public: false, duration: 45).first_or_create! do |f|
      f.description = "Keynote"
    end

    # --- Rooms ---------------------------------------------------------------
    hall_large = event.rooms.where(name: "大ホール").first_or_create! do |r|
      r.room_number = "L"
      r.level = "1"
      r.capacity = 600
    end
    hall_small = event.rooms.where(name: "小ホール").first_or_create! do |r|
      r.room_number = "S"
      r.level = "2"
      r.capacity = 300
    end

    # --- Team ----------------------------------------------------------------
    event.teammates.where(user: admin, email: admin.email).first_or_create!(role: "organizer", mention_name: "admin", state: :accepted)
    event.teammates.where(user: organizer, email: organizer.email).first_or_create!(role: "organizer", mention_name: "organizer", state: :accepted)
    event.teammates.where(user: reviewer, email: reviewer.email).first_or_create!(role: "reviewer", mention_name: "reviewer", state: :accepted)

    # --- Proposals -----------------------------------------------------------
    proposals_data = [
      { key: :hotwire,    speaker: :yui,    format: talk30, state: "submitted",
        title: "Hotwireで作るリアルタイム管理画面の実践",
        abstract: "Hotwire（Turbo + Stimulus）を使い、SPAフレームワークなしでリアルタイム更新される管理画面を構築した事例を紹介します。",
        bio: "Webアプリケーション開発者。Hotwireが好きです。" },
      { key: :locking,    speaker: :kenta,  format: talk30, state: "submitted",
        title: "Active Recordのロックを正しく使う：悲観的ロックと楽観的ロックの使い分け",
        abstract: "在庫管理システムで実際に起きた競合状態を題材に、Active Recordのロック機構の使い分けと落とし穴を解説します。",
        bio: "ECサイトのバックエンドを開発しています。" },
      { key: :solid_queue, speaker: :misaki, format: talk30, state: "submitted",
        title: "Rails 8のSolid Queueでジョブ基盤を再構築した話",
        abstract: "Sidekiq + RedisからSolid Queueへ移行した経験をもとに、移行戦略・パフォーマンス・運用の変化を共有します。",
        bio: "SREとRailsの間で生きています。" },
      { key: :monolith,   speaker: :daichi, format: talk30, state: "soft accepted",
        title: "巨大モノリスを「分けない」勇気：境界づけられたコンテキストとpacks-rails",
        abstract: "マイクロサービス化せずにモノリスの内部構造を整理する道を選んだチームの3年間の記録です。",
        bio: "10年もののRailsアプリと格闘中。" },
      { key: :view_component, speaker: :aoi, format: talk15, state: "soft rejected",
        title: "ViewComponentとHotwireによるフロントエンド設計",
        abstract: "ViewComponentでUIを部品化しつつ、Hotwireと組み合わせる際の設計パターンとテスト戦略を紹介します。",
        bio: "デザインシステムとRailsの橋渡しをしています。" },
      { key: :nplusone,   speaker: :ren,    format: talk15, state: "soft waitlisted",
        title: "実録・N+1との戦い：Railsアプリのパフォーマンス改善",
        abstract: "計測なくして改善なし。rack-mini-profilerとdatadogを駆使してレスポンスタイムを1/10にした道のりです。",
        bio: "パフォーマンスチューニングが趣味です。" },
      { key: :rbs,        speaker: :hana,   format: talk30, state: "accepted", confirmed: true,
        title: "RBSとSteepで型のあるRails開発",
        abstract: "型検査をRailsプロジェクトに段階的に導入する現実的な手順と、チームに定着させるための工夫を話します。",
        bio: "型と仲良くなりたいRubyist。" },
      { key: :multitenant, speaker: :sota,  format: talk30, state: "accepted", confirmed: true,
        title: "マルチテナントSaaSにおけるデータ分離戦略",
        abstract: "Row-level securityからスキーマ分離まで、マルチテナントSaaSのデータ分離手法をRailsでの実装例とともに比較します。",
        bio: "BtoB SaaSのアーキテクトをしています。" },
      { key: :kamal,      speaker: :yui,    format: talk15, state: "withdrawn",
        title: "Kamalで実現するシンプルなデプロイ",
        abstract: "Kubernetesを使わずKamalでコンテナデプロイをシンプルに保つ構成を紹介します。",
        bio: "Webアプリケーション開発者。Hotwireが好きです。" },
      { key: :slow_test,  speaker: :kenta,  format: talk15, state: "submitted",
        title: "テストが遅い問題と向き合う：CI 40分から8分への道",
        abstract: "並列化・不要なセットアップの削減・flakyテストの撲滅など、テスト高速化の具体的な手法を紹介します。",
        bio: "ECサイトのバックエンドを開発しています。" },
      { key: :a11y,       speaker: :misaki, format: talk15, state: "submitted",
        title: "Railsエンジニアのためのアクセシビリティ入門",
        abstract: "フォーム・モーダル・ライブリージョンを題材に、Railsのビュー層でできるアクセシビリティ改善を解説します。",
        bio: "SREとRailsの間で生きています。" },
      { key: :i18n,       speaker: :aoi,    format: talk15, state: "submitted",
        title: "I18nの落とし穴：多言語Railsアプリ運用の現場から",
        abstract: "lazy lookup、複数形、タイムゾーン……多言語対応で踏み抜いた地雷とその回避策をまとめます。",
        bio: "デザインシステムとRailsの橋渡しをしています。" },
    ]

    created_proposals = {}
    proposals_data.each_with_index do |data, i|
      # NOTE: uuid is regenerated by Proposal#set_uuid on create, so title is the idempotency key
      proposal = event.proposals.where(title: data[:title]).first_or_initialize
      if proposal.new_record?
        proposal.assign_attributes(
          state: data[:state],
          session_format: data[:format],
          title: data[:title],
          abstract: data[:abstract],
          details: "#{data[:abstract]}\n\nセッションでは実際のコードとベンチマーク結果を交えて解説します。",
          pitch: "実務で得た知見をコミュニティに還元したいです。",
          confirmed_at: data[:confirmed] ? Time.current : nil,
          created_at: (30 - i).days.ago
        )
        proposal.save!
      end
      user = speakers[data[:speaker]]
      proposal.speakers.where(user: user, event: event).first_or_create!(
        speaker_name: user.name,
        speaker_email: user.email,
        bio: data[:bio]
      )
      created_proposals[data[:key]] = proposal
    end

    # --- Ratings & comments --------------------------------------------------
    rate = ->(proposal, user, score) { proposal.ratings.where(user: user).first_or_create!(score: score) }
    %i[hotwire locking solid_queue monolith view_component nplusone rbs multitenant slow_test].each_with_index do |key, i|
      rate.call(created_proposals[key], organizer, (i % 5) + 1)
      rate.call(created_proposals[key], reviewer, ((i + 2) % 5) + 1)
    end

    organizer.comments.where(proposal: created_proposals[:hotwire], type: "PublicComment")
      .first_or_create!(body: "とても面白そうです！対象とする聴衆のレベル感を教えていただけますか？")
    reviewer.comments.where(proposal: created_proposals[:monolith], type: "InternalComment")
      .first_or_create!(body: "実体験ベースで説得力がある。採択推し。")
    reviewer.comments.where(proposal: created_proposals[:rbs], type: "InternalComment")
      .first_or_create!(body: "型の話は毎年人気。30分でちょうどよさそう。")

    # --- Program sessions & schedule ------------------------------------------
    keynote_session = event.program_sessions.where(title: "基調講演").first_or_create!(
      state: :live,
      abstract: "Kaigi on Rails 2026の幕開けを飾る基調講演です。",
      session_format: keynote_format
    )

    live_sessions = {}
    %i[rbs multitenant].each do |key|
      proposal = created_proposals[key]
      session = event.program_sessions.where(proposal: proposal).first_or_create!(
        state: :live,
        title: proposal.title,
        abstract: proposal.abstract,
        session_format: proposal.session_format
      )
      proposal.speakers.each { |sp| sp.update!(program_session: session) }
      live_sessions[key] = session
    end

    slot = ->(attrs) do
      record = event.time_slots.where(attrs.slice(:conference_day, :room, :start_time)).first_or_initialize
      record.assign_attributes(attrs)
      record.save!(validate: false)
    end

    slot.call(conference_day: 1, room: hall_large, start_time: "10:00", end_time: "10:45", program_session: keynote_session)
    slot.call(conference_day: 1, room: hall_large, start_time: "11:00", end_time: "11:30", program_session: live_sessions[:rbs])
    slot.call(conference_day: 2, room: hall_small, start_time: "13:00", end_time: "13:30", program_session: live_sessions[:multitenant])
    slot.call(conference_day: 2, room: hall_large, start_time: "12:00", end_time: "13:00", title: "ランチ休憩", description: "", presenter: "")

    # --- Website (themed public site) ----------------------------------------
    website = Website.where(event: event).first_or_create! do |site|
      site.city = "Tokyo"
      site.navigation_links = %w[program schedule sponsors]
      site.footer_about_content = "Kaigi on RailsはRuby on Railsに関するテックカンファレンスです。"
      site.footer_copyright = "© 2026 Kaigi on Rails"
      site.twitter_handle = "kaigionrails"
    end

    event.session_formats.each_with_index do |sf, i|
      config = website.session_format_configs.where(session_format: sf).first_or_initialize
      config.name ||= sf.name
      config.position ||= i + 1
      config.display = true if config.respond_to?(:display)
      config.save!
    end

    landing_body = <<~HTML
      <h1>Kaigi on Rails 2026</h1>
      <p>2026年10月16日（金）・17日（土）開催。Kaigi on RailsはRuby on Railsに関するテックカンファレンスです。</p>
      <h2>Call for Proposals</h2>
      <p>トークの応募を2026年7月12日まで受け付けています。15分または30分のトークを募集中です。初めての登壇も歓迎します！</p>
      <a class="btn btn-primary" href="/events/2026/proposals/new">プロポーザルを提出する</a>
    HTML
    landing = website.pages.where(slug: "home").first_or_initialize
    landing.assign_attributes(name: "Home", landing: true, hide_page: false,
                              published_body: landing_body, unpublished_body: landing_body)
    landing.save!

    # --- Sponsors --------------------------------------------------------------
    sponsor_logo = ->(name, color) do
      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="320" height="120" viewBox="0 0 320 120">
          <rect width="320" height="120" rx="12" fill="#{color}"/>
          <text x="160" y="68" text-anchor="middle" font-family="sans-serif" font-size="28" font-weight="bold" fill="#ffffff">#{name}</text>
        </svg>
      SVG
      { io: StringIO.new(svg), filename: "#{name.parameterize}.svg", content_type: "image/svg+xml" }
    end

    [
      { name: "Ruby商事",            tier: "platinum",  color: "#ff2e9b" },
      { name: "Rails Studio",        tier: "gold",      color: "#7445C0" },
      { name: "Turbo Logistics",     tier: "gold",      color: "#3444DA" },
      { name: "Hotwire Works",       tier: "silver",    color: "#417D7A" },
      { name: "Kamal Cloud",         tier: "silver",    color: "#EA652C" },
      { name: "Solid Cache Foods",   tier: "supporter", color: "#5A5655" },
    ].each do |data|
      sponsor = event.sponsors.where(name: data[:name]).first_or_initialize
      next unless sponsor.new_record?
      sponsor.assign_attributes(
        tier: data[:tier],
        url: "https://example.com/#{data[:name].parameterize}",
        description: "#{data[:name]}はKaigi on Rails 2026を応援しています。",
        published: true
      )
      sponsor.primary_logo.attach(sponsor_logo.call(data[:name], data[:color]))
      sponsor.save!
    end

    puts "Kaigi on Rails 2026 seed complete:"
    puts "  Event:     /events/#{event.slug} (state: #{event.state})"
    puts "  Proposals: #{event.proposals.count}"
    puts "  Sessions:  #{event.program_sessions.count} (live)"
    puts "  Sponsors:  #{event.sponsors.count}"
    puts "  Website:   /#{event.slug} (landing, program, schedule, sponsors)"
  ensure
    ActionMailer::Base.perform_deliveries = perform_deliveries_orig
  end
end
