# -*- encoding : utf-8 -*-
class ClassSuggestionWorker
  include Sidekiq::Worker

  @@test_v = ClassGenerator.generate(10)

  @@rooms = [
    [ #tipo 0
      { #sala
        code: "A305",
        capacity: 40,
        hours: "2456M1234 24N12"
      },#fim sala
      { #sala
        code: "A101",
        capacity: 20,
        hours: "2456M1234 56T34 2N1234"
      } #fim sala
    ], #fim tipo 0

    [ #tipo 1
      { #sala
        code: "A306",
        capacity: 40,
        hours: "2456M1234 456T12"
      } #fim sala
    ], #fim tipo 1

    [ #tipo 2
      { #sala
        code: "A307",
        capacity: 40,
        hours: "2456M1234 56T34 2N1234"
      } #fim sala
    ] #fim tipo 2
  ]

  def perform(classes, rooms)
    @classes = classes
    $redis.set('classes', classes.to_json)
    $redis.set('rooms', rooms.to_json)

    $redis.set('status', 'generate_possibilities')
    mass_slot_generator(expand_suggestion_list(classes, rooms))
  end

  private

  def valid_room?(room, slot, capacity)
    room.symbolize_keys!

    return false if room[:capacity] < capacity

    days, hours = slot[:hours].split(/[MTN]/)
    shift = slot[:hours].scan(/[MTN]/)[0]

    r_days, r_hours = room[:hours].scan(/\d+[#{shift}]\d+/)[0].split(shift) rescue return false

    return (r_days.chars - days.chars).length == r_days.length - days.length && (r_hours.chars - hours.chars).length == r_hours.length - hours.length

  end

  def generate_all_suggestions(sugg, preference, rooms, capacity)

    aux = []

    sugg.each do |slot|
      slot.symbolize_keys!
      aux << rooms[slot[:room_type]].map do |room|
        {code: room[:code], hours: slot[:hours]} if valid_room?(room, slot, capacity)
      end.compact
    end

    aux[0].product(*aux[1..-1]).map do |x|

      {preference: preference, room: x}

    end

  end

  def expand_suggestion_list(s_list, rooms)

    r = []

    s_list = s_list.map(&:symbolize_keys)
    rooms = rooms.each{|vectors| vectors.map(&:symbolize_keys) }

    s_list.each do |course|

      aux = []

      # raise Exception.new course

      course[:suggestions].each_with_index do |sugg, ss_index|

        generate_all_suggestions(sugg, ss_index, rooms, course[:capacity]).each do |x|
          aux << x
        end

      end

      r << aux
    end

    r

  end

  def mass_slot_generator(preferences)
    total_to_process = preferences[0].length

    1.upto(preferences.length - 1) do |i|
      total_to_process *= preferences[i].length
    end

    $redis.set('status', 'removing_conflicts')

    $redis.set('total_to_process', total_to_process)
    $redis.set('processed', 0)

    # PartitionSolutionAnaliserWorker.new(6).perform(preferences)

    x = []

    #lembrar de rodar com alguma amostra que tenha resultados possíveis logo de cara
    #lembrar de rodar com alguma amostra que tenha resultados possíveis só no fim

    #(0..2).to_a.repeated_combination(3).to_a.sort { |x, y| if ((x.sum <=> y.sum) == 0); x.max <=> y.max; else; x.sum <=> y.sum; end; }

    0.upto(preferences[0].length - 1) do |i|
      PartitionSolutionAnaliserWorker.perform_async(preferences, @classes, i)
    end
  end

end
