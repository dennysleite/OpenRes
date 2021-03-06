# -*- encoding : utf-8 -*-
require 'spec_helper'

feature 'Redirect to correct dashboard' do
  before do
    @admin = create(:admin)
    @sector_admin = create(:sector_admin)
    @secretary = create(:secretary)
    @basic = create(:user)
  end

  scenario 'login as admin' do
    sign_in(@admin)

    expect(page).to have_content("Autenticado com sucesso.")
  end

  scenario 'login as sector_admin' do
    sign_in(@sector_admin)

    expect(page).to have_content("Autenticado com sucesso.")
  end

  scenario 'login as secretary' do
    sign_in(@secretary)

    expect(page).to have_content("Autenticado com sucesso.")
  end

  scenario 'login as basic user' do
    sign_in(@basic)

    expect(page).to have_content("Autenticado com sucesso.")
  end

  #temporary
  def sign_in(user)
    visit new_user_session_path

    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_button 'Entrar'
  end
end
