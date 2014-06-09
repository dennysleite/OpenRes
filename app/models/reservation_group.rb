# -*- encoding : utf-8 -*-
class ReservationGroup < ActiveRecord::Base
  has_many :reservations


  scope :from_user, lambda{ |user|
    ReservationGroup.where(user_id: user.id)
  }

  scope :from_sector, lambda { |sector|

    reservations = []

    ReservationGroup.all.each do |reservation|

      if reservation.sectors_ids.include? sector.id

        reservations << reservation
      end
    end

    return reservations
  }

  scope :from_sectors, lambda { |sector_ids|

    reservations = []

    ReservationGroup.all.each do |reservation|

      if (reservation.sectors_ids - sector_ids).length < reservation.sectors_ids.length 

        reservations << reservation
      end
    end

    return reservations
  }

  scope :from_place, lambda { |place|

    reservations = []

    ReservationGroup.all.each do |reservation|

      if reservation.place.id == place.id
        reservations << reservation
      end
    end

    return reservations
  }


  scope :from_future, lambda{
    reservations = []

    ReservationGroup.all.each do |reservation|

      if reservation.begin_date >= DateTime.now.to_date
        reservations << reservation
      end
    end

    return reservations
  }

  scope :from_past, lambda{
    reservations = []

    ReservationGroup.all.each do |reservation|

      if reservation.begin_date < DateTime.now.to_date
        reservations << reservation
      end
    end

    return reservations
  }

  scope :can_decide_over, lambda { |user|
    return ReservationGroup.none if user.nil? || user.role == "basic"
    return ReservationGroup.all if user.role == "admin"
    return ReservationGroup.from_sectors(user.sector_ids) # if user.role == 'secretary' or 'sector_admin'
  }


  def sectors_ids
    place.sector_ids
  end

  def responsible
    return reservations.first.responsible
  end

  def place_name
    reservations.first.place.name
  end

  def place
    reservations.first.place
  end

  def user
    reservations.first.user
  end

  def begin_date
    reservations.first.date
  end

  def end_date
    reservations.last.date
  end

  def days
    my_days = []
    reservations.each do |r|
      my_days << r.date.wday
    end
    my_days.uniq
  end

  def status
    status =[]
    reservations.each do |r|
      status << r.status
    end

    status = status.uniq

    if status.length == 1
      if status[0] == "approved"
        return "approved"
      elsif status[0] =="pending"
        return "pending"
      else
        return "rejected"
      end
    elsif status.include? "approved"
      return "partially approved"
    else status.include? "pending"
      return "partially pending"
    end

  end

  def can_be_decided_over?(ap_user)
    reservations.first.can_be_decided_over?(ap_user)
  end

  def has_conflicts?
    reservations.each do |r|
      return true if r.has_conflicts?
    end

    false
  end
end
