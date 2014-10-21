# -*- encoding : utf-8 -*-
class ReservationPolicy

  def self.suspend(current_user, reservation, justification, opts={})

    return unless reservation.can_be_decided_over? current_user

    reservation.status = "pending"

    ActiveRecord::Base.transaction do
      justification.save
      reservation.save
    end
    unless opts[:silent]
      ReservationApprovalMailer.suspended_mail(reservation, justification).deliver
      NotifyUserMailer.send_reservation_to_class_monitor(reservation)
    end
  end

  def self.reject(current_user, reservation, justification, opts={})
    reservation.status = "rejected"

    ActiveRecord::Base.transaction do
      justification.save
      reservation.save
    end
    unless opts[:silent]
      ReservationApprovalMailer.rejected_mail(reservation, justification).deliver
      NotifyUserMailer.send_reservation_to_class_monitor(reservation)
    end
  end

  def self.approve(current_user, reservation, opts={})

    conflicts = Reservation.approved.conflicting(reservation)

    if conflicts.empty?
      reservation.status = "approved"

      unless opts[:silent]
        ReservationApprovalMailer.approved_mail(reservation).deliver
        NotifyUserMailer.send_reservation_to_class_monitor(reservation)
      end

      reservation.save
    end

    return conflicts
  end

  def self.cancel(current_user, reservation, opts={})
    reservation.status = "canceled"
    reservation.save

    unless opts[:silent]
      NotifyUserMailer.send_canceled_mail(reservation).deliver
      NotifyUserMailer.send_reservation_to_class_monitor(reservation)
    end

  end

  def self.delete(current_user, reservation, opts={})
    reservation.destroy
  end

  def self.suspend_all(current_user, reservation_group, justification)

    reservation_group.reservations.each do |reservation|
      ReservationPolicy.suspend(current_user, reservation, justification, {silent: true})
    end

    ReservationApprovalMailer.suspended_group_mail(reservation_group, justification).deliver
    NotifyUserMailer.send_reservation_to_class_monitor(reservation_group)
  end

  def self.reject_all(current_user, reservation_group, justification)

    reservation_group.reservations.each do |reservation|
      ReservationPolicy.reject(current_user, reservation, justification, {silent: true})
    end

    ReservationApprovalMailer.rejected_group_mail(reservation_group, justification).deliver
    NotifyUserMailer.send_reservation_to_class_monitor(reservation_group)

  end

  def self.approve_all(current_user, reservation_group)

    conflicts = []

    reservation_group.reservations.each do |reservation|
      ReservationPolicy.approve(current_user, reservation, {silent: true})
    end

    ReservationApprovalMailer.approved_group_mail(reservation_group).deliver
    NotifyUserMailer.send_reservation_to_class_monitor(reservation_group)

    return conflicts

  end

  def self.cancel_all(current_user, reservation_group, opts={})

    reservation_group.reservations.each do |reservation|
      ReservationPolicy.cancel(current_user, reservation, {silent: true})
    end

    reservation_group.save
    NotifyUserMailer.send_canceled_group_mail(reservation_group)
    NotifyUserMailer.send_reservation_to_class_monitor(reservation_group)
  end

end
