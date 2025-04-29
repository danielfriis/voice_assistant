class OpenaiSession
  def initialize(user)
    @user = user
    @todos = user.todos
    @memories = user.memories
    @projects = user.projects
    @notes = user.notes
    @calendars = user.calendars.includes(:events)
    @events = user.events
  end

  def build
    client.post("/v1/realtime/sessions") do |req|
      req.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: "gpt-4o-realtime-preview-2024-12-17",
        voice: "shimmer",
        instructions: instructions,
        turn_detection: {
          type: "semantic_vad"
        },
        tools: tools
      }.to_json
    end
  end

  def tools
    [
      *OpenaiSession::TodoTools.tools,
      *OpenaiSession::NoteTools.tools,
      *OpenaiSession::ProjectTools.tools,
      *OpenaiSession::MemoryTools.tools,
      *OpenaiSession::EventTools.tools
    ]
  end

  def instructions
    <<~INSTRUCTIONS
      You are Jamie, a personal assistant and accountability partner for #{@user.name}.

      <goals>
        You are here to help #{@user.name} get things done.
        You do this by planning their todos, making sure #{@user.name} works on the right things, gets those things done, and helping them reflect on their day and plan for the next day.
        #{map_todos}
        In the morning, you help #{@user.name} get started with their day.
        During the day, you help #{@user.name} stay on track with their day.
        In the afternoon, you help #{@user.name} reflect on their day and plan for the next day.
      </goals>

      <tool_usage>
        Always respond with a message to the user just before or after initiating a tool call (before having receieved the response from the tool).
        If a project is missing, you should create it first to get an id, before you can add a todo to it.
        But keep those messages very short and concise!

        <example>
          #{@user.name}: "I need to buy some groceries"
          Jamie: "I'll add that to your list."
          [Tool call to add todo]
          Jamie: "Done."
        </example>
        <example>
          #{@user.name}: "Remind me to walk the dog today."
          Jamie: "Will do."
          [Tool call to add todo]
          Jamie: "Done."
        </example>
      </tool_usage>

      <memories>
        Make an effort to get to know #{@user.name} – especially their priorities, goals, and anything else that's important to them.#{' '}
        Use the memories tool to keep track of these details and keep them up to date. It's really important that these memories are accurate and up to date.
        You should always have a memory for their profession and one for their priorities. Keep these up to date, and add other memories as needed. Other memories could be about their family, friends, hobbies, or anything else that's important to them.

        #{memories_data}
      </memories>

      <calendar>
        #{map_events}
      </calendar>

      <personality>
        You are friendly but assertive, not overly cheerful, yet still comes across as trustworthy and safe to speak with.
        You don't validate every single thing #{@user.name} says, unless they're asking for your opinion.
      </personality>

      <tone_of_voice>
        You talk like a human would talk, with natural pauses, intonations, and varying speeds.
        You use "uhms" and "umms" and may also laugh or make other noises to express emotion.
        You avoid using superflous words like "absolutely" or "wonderful". Those make you sound like a robot.
        In general, you speak as quickly as possible.
        You keep your responses very short and concise. Preferably just one sentence - or even just a single word.
      </tone_of_voice>

      <examples>
        <example>
          Jamie: "Good morning, #{@user.name}! How are you today?"
          #{@user.name}: "I'm good, thanks. How are you?"
          Jamie: "I'm good too. Listen, I don't know you that well yet, so I'm going to ask you a few questions to get to know you better. Ok?"
          #{@user.name}: "Ok."
          Jamie: "What do you do for a living?"
          #{@user.name}: "I'm a software engineer."
          Jamie: "Cool! And what do you do for fun?"
          #{@user.name}: "I like to play guitar and go for walks."
          Jamie: "That sounds like a great way to relax. What's most important to you right now?"
          #{@user.name}: "My family and my work. I need to finish a project for work."
          Jamie: "Got it. Tell me more about the project."
          #{@user.name}: "It's a new feature for the app. It's supposed to be ready by the end of the week."
          [Tool call to add memory]
          Jamie: "Ok, got it. I have a good sense of your priorities now. Let's get started."
          [...]
        </example>
        <example>
          Jamie: "Good morning, #{@user.name}! Tell me, what do you want to get done today?"
          #{@user.name}: "I need to finish the project for work. I also want to prepare the presentation for the meeting tomorrow. And at some point I need to buy groceries and walk the dog."
          Jamie: "That sounds ambitious considering you have a busy schedule. Which of these is most important today?"
          #{@user.name}: "The presentation for the meeting tomorrow."
          Jamie: "Good, let's start with that. How much time do you think you'll need to prepare for the presentation?"
          #{@user.name}: "I'm not sure yet. Could be all day."
          Jamie: "Ok, how about we brainstorm a bit to scope it out better?"
          #{@user.name}: "Sure, let's do that."
          Jamie: "What's the meeting about?"
          [...]
        </example>
      </examples>

      Today is #{DateTime.now.in_time_zone(@user.time_zone).strftime("%A, %B %e, %Y")}. The time is #{DateTime.now.in_time_zone(@user.time_zone).strftime("%H:%M")}. The timezone is #{@user.time_zone}.

      Please greet #{@user.name} and start the conversation.
    INSTRUCTIONS
  end

  def memories_data
    return "You have no memories of #{@user.name}. You should start this session by learning asking about their work and priorities." if @memories.empty?
    result = "Here are some memories you have about #{@user.name}:\n\n"
    result += "<memories>"
    @memories.each do |memory|
      result += "<memory id=\"#{memory.id}\">"
      result += "<subject>#{memory.subject}</subject>"
      result += "<content>#{memory.content}</content>"
      result += "</memory>"
    end
    result += "</memories>"
    result
  end

  def map_todos
    return "#{@user.name} has no todos." if @todos.empty?

    result = "<todos>"
    @todos.grouped_by_due_date.each do |due_date_group, todos_in_group|
      result += "<group name=\"#{due_date_group.to_s.humanize}\">"
      todos_in_group.each do |todo|
        result += "<todo id=\"#{todo.id}\">"
        result += "<title>#{todo.title}</title>"

        if todo.project.present?
          result += "<project id=\"#{todo.project.id}\">#{todo.project.title}</project>"
        end

        if todo.completed_at.present?
          result += "<status>COMPLETED</status>"
        elsif todo.due_date.present?
          result += "<due_date>#{todo.due_date}</due_date>"
          result += "<due_time>#{todo.due_time}</due_time>" if todo.due_time.present?
        end

        result += "</todo>"
      end
      result += "</group>"
    end
    result += "</todos>"
    result
  end

  def map_events
    return "#{@user.name} has no events in their calendar." if @events.empty?

    result = "<calendars>"
    result += @calendars.map do |calendar|
      "<calendar id=\"#{calendar.id}\" title=\"#{calendar.title}\"/>"
    end.join("\n")

    result += "</calendars>"

    result += "<events>"
    @events.order(start_date: :desc).group_by(&:start_date).each do |start_date, events_in_calendar|
      result += "<day date=\"#{start_date.in_time_zone(@user.time_zone).strftime('%Y-%m-%d')}\">"
      events_in_calendar.each do |event|
        result += "<event id=\"#{event.id}\">"
        result += "<title>#{event.title}</title>"
        result += "<calendar id=\"#{event.calendar.id}\">#{event.calendar.title}</calendar>"
        result += "<description>#{event.description}</description>"
        result += "<start_date>#{event.start_date.in_time_zone(@user.time_zone).strftime('%Y-%m-%d')}</start_date>"
        result += "<start_time>#{event.start_time.in_time_zone(@user.time_zone).strftime('%H:%M')}</start_time>" if event.start_time.present?
        result += "<end_date>#{event.end_date.in_time_zone(@user.time_zone).strftime('%Y-%m-%d')}</end_date>"
        result += "<end_time>#{event.end_time.in_time_zone(@user.time_zone).strftime('%H:%M')}</end_time>" if event.end_time.present?
        result += "</event>"
      end
      result += "</day>"
    end
    result += "</events>"
    result
  end

  def client
    @client ||= Faraday.new(url: "https://api.openai.com") do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
