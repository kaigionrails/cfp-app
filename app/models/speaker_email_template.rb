class SpeakerEmailTemplate
  TYPES = [:all, :accept, :waitlist, :reject ]

  DISPLAY_TYPES = {
      all: 'All',
      accept: 'Accept',
      waitlist: 'Waitlist',
      reject: 'Not Accepted'
  }.with_indifferent_access

  TYPES_TO_STATES = {
      all: :submitted,
      accept: :accepted,
      waitlist: :waitlisted,
      reject: :rejected
  }.with_indifferent_access

  attr_accessor :email, :type_key
end
