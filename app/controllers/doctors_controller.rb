class DoctorsController < ApplicationController
  before_action :authenticate_doctor!

  before_action :set_doctor, only: [:show, :edit, :update, :destroy, :info, :reset_password]
  before_action :assert_superuser, only: [:index, :destroy, :new]
  before_action :assert_accessing_own_profile, only: [:edit, :update, :reset_password]
  before_action :set_patient, only: [:info]

  def index
  end

  def info
    if(current_doctor.superuser)
      @recent_patients = Patient.all
    else
      @recent_patients = current_doctor.patients.order(:updated_at)
    end
    @treatment_states = @patient.treatment_states if @patient
  end

  def show
    respond_with(@doctor)
  end

  def new
    @doctor = Doctor.new
    respond_with(@doctor)
  end

  def edit
  end

  def create
    @doctor = Doctor.new(doctor_params)
    set_random_password_for @doctor
    if(@doctor.save)
      flash[:success] = "Successfully created new account for #{@doctor.name}"
      render '/doctors/created'
    else
      flash[:error] = @doctor.errors.full_messages.first
      redirect_to new_doctor_path
    end

  end

  def update
    # Is nil if password or password_confirmation are NOT blank
    changed_params = doctor_params.select! { |key, value| !(['password', 'password_confirmation'].include?(key.to_s) and value.blank?) }


    if(@doctor.update((changed_params or doctor_params)))

      flash[:success] = "Successfully updated account for #{@doctor.name}"
      redirect_to doctors_path
    else

      flash[:error] = @doctor.errors.full_messages.first 
      redirect_to edit_doctor_path(@doctor)
    end

  end

  def destroy
    @doctor.destroy
    respond_with(@doctor)
  end

  def reset_password
    set_random_password_for @doctor
    flash.now[:success] = "Successfully reset password"
    render '/doctors/created'
  end

  def search
    @doctor = Doctor.find_by_email(params[:email])
    unless @doctor
      flash[:error] = "No doctor with that email was found"
      redirect_to doctors_path and return
    end
    render :edit
  end

  private

  def set_random_password_for(doctor)
    @password = Faker::Lorem.words(2).join('-')
    doctor.password = @password
    doctor.password_confirmation = @password
    doctor.save
  end

  def set_patient
    @patient = Patient.find_by_id(params[:id])
  end

  def set_treatment_states
    if(@focused_patient)
      @treatment_states = TreatmentState.includes(treatment_modules: :data_module).where(pathway: @focused_patient.pathway)
    end
  end

  def set_doctor
    @doctor = Doctor.find_by_id(params[:id]) || current_doctor
  end

  def doctor_params
    params.require(:doctor).permit(:name, :email, :contact_details, :password, :password_confirmation, :superuser, team_ids: [])
  end

  def assign_patients
    @doctor.patients
  end

  def set_random_password_for(doctor)
    @password = Faker::Lorem.words(2).join('-')
    doctor.password = @password
    doctor.password_confirmation = @password
    doctor.save
  end

end
