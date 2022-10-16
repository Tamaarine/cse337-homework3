class ValueError < RuntimeError
end

class Cave
  def initialize()
    @edges = [[1, 2], [2, 10], [10, 11], [11, 8], [8, 1], [1, 5], [2, 3], [9, 10], [20, 11], [7, 8], [5, 4],
                      [4, 3], [3, 12], [12, 9], [9, 19], [19, 20], [20, 17], [17, 7], [7, 6], [6, 5], [4, 14], [12, 13],
                      [18, 19], [16, 17], [15, 6], [14, 13], [13, 18], [18, 16], [16, 15], [15, 14]]
    @rooms = {}
    (1..20).to_a.each {|i| @rooms[i] = Room.new(i)}   # Create the rooms and put it in the dict
    @edges.each {|edge| @rooms[edge[0]].connect(@rooms[edge[1]])}   # Connect the rooms
  end
  
  def add_hazard(h, n)
    added = 0
    while added < n
      picked = rand(1..20)
      if not @rooms[picked].has?(h)
        @rooms[picked].add(h)
        added += 1
      end
    end
  end
  
  def random_room
    @rooms[(1..20).to_a.sample]
  end
  
  def room_with(hazard)
    @rooms.values.find {|room| room.has?(hazard)}
  end
  
  def move(hazard, frm, to)
    if frm.has?(hazard)
      frm.remove(hazard)
      to.add(hazard)
    else
      raise ValueError.new("#{hazard} doesn't exist in room \##{frm.number}")
    end
  end
end

class Player
  # add specified Player methods
end

class Room
  attr_reader :number, :hazards, :neighbors
  
  def initialize(number)
    @number = number        # Room #
    @hazards = []           # List of hazards this room can contain
    @neighbors = []         # List of neighbors this room connects to
  end
  
  def add(hazard)
    @hazards.push(hazard)
  end
  
  def has?(hazard)
    @hazards.include?(hazard)
  end
  
  def remove(hazard)
    if has?(hazard)
      @hazards.delete(hazard)
    else
      raise ValueError.new("The hazard doesn't exist")
    end
  end
  
  def empty?
    @hazards.empty?
  end
  
  def safe?
    # Select neighbors that's unsafe, if unsafe neighbors is 0
    # and make sure current room is safe too then is safe
    (@neighbors.select {|room| not room.empty?}).length == 0 and empty?
  end
  
  def connect(other_room)
    @neighbors.push(other_room)       # Add to self neighbor
    other_room.neighbors.push(self)   # Add self to other_room's neighbors
  end
  
  def exits
    ret = Array.new
    @neighbors.each {|room| ret.push(room.number)}
    return ret
  end
  
  def neighbor(number)
    ret = @neighbors.index {|room| room.number == number}
    ret != nil ? @neighbors[ret] : ret
  end
  
  def random_neighbor
    if @neighbors.length != 0
      @neighbors[rand(0...@neighbors.length)]
    else
      raise IndexError.new("Room has no neighbor")
    end
  end
end

class Console
  def initialize(player, narrator)
    @player   = player
    @narrator = narrator
  end

  def show_room_description
    @narrator.say "-----------------------------------------"
    @narrator.say "You are in room #{@player.room.number}."

    @player.explore_room

    @narrator.say "Exits go to: #{@player.room.exits.join(', ')}"
  end

  def ask_player_to_act
    actions = {"m" => :move, "s" => :shoot, "i" => :inspect }

    accepting_player_input do |command, room_number|
      @player.act(actions[command], @player.room.neighbor(room_number))
    end
  end

  private

  def accepting_player_input
    @narrator.say "-----------------------------------------"
    command = @narrator.ask("What do you want to do? (m)ove or (s)hoot?")

    unless ["m","s"].include?(command)
      @narrator.say "INVALID ACTION! TRY AGAIN!"
      return
    end

    dest = @narrator.ask("Where?").to_i

    unless @player.room.exits.include?(dest)
      @narrator.say "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
      return
    end

    yield(command, dest)
  end
end

class Narrator
  def say(message)
    $stdout.puts message
  end

  def ask(question)
    print "#{question} "
    $stdin.gets.chomp
  end

  def tell_story
    yield until finished?

    say "-----------------------------------------"
    describe_ending
  end

  def finish_story(message)
    @ending_message = message
  end

  def finished?
    !!@ending_message
  end

  def describe_ending
    say @ending_message
  end
end
