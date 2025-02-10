# contact_manager.rb
require 'json'
require 'set'

class ContactManager
  def initialize(file_path = 'contacts.json')
    @file_path = file_path
    @contacts = []
    @search_index = {}
    load_contacts
    build_search_index
  end

  # Existing create_contact method remains the same
  def create_contact(name, phone, email)
    return { success: false, message: "Name cannot be empty" } if name.nil? || name.strip.empty?
    return { success: false, message: "Invalid phone number" } unless valid_phone?(phone)
    return { success: false, message: "Invalid email" } unless valid_email?(email)

    contact = {
      'id' => generate_id,
      'name' => name.strip,
      'phone' => phone.strip,
      'email' => email.strip,
      'created_at' => Time.now.to_s
    }

    @contacts << contact
    add_to_search_index(contact, @contacts.length - 1)
    save_contacts

    { success: true, message: "Contact created successfully", contact: contact }
  end

  # New method: Update contact
  def update_contact(id)
    contact_index = @contacts.find_index { |c| c['id'] == id }
    return { success: false, message: "Contact not found" } unless contact_index

    print "Enter new name (press Enter to keep existing): "
    new_name = gets.chomp
    print "Enter new phone (press Enter to keep existing): "
    new_phone = gets.chomp
    print "Enter new email (press Enter to keep existing): "
    new_email = gets.chomp

    # Update only if new values are provided
    @contacts[contact_index]['name'] = new_name unless new_name.empty?
    @contacts[contact_index]['phone'] = new_phone unless new_phone.empty?
    @contacts[contact_index]['email'] = new_email unless new_email.empty?
    @contacts[contact_index]['updated_at'] = Time.now.to_s

    build_search_index  # Rebuild search index after update
    save_contacts

    { success: true, message: "Contact updated successfully", contact: @contacts[contact_index] }
  end

  # New method: Delete contact
  def delete_contact(id)
    contact_index = @contacts.find_index { |c| c['id'] == id }
    return { success: false, message: "Contact not found" } unless contact_index

    deleted_contact = @contacts.delete_at(contact_index)
    build_search_index  # Rebuild search index after deletion
    save_contacts

    { success: true, message: "Contact deleted successfully", contact: deleted_contact }
  end

  # Rest of the existing methods remain the same
  def search(query)
    return @contacts if query.nil? || query.strip.empty?
    
    query = query.downcase.strip
    matching_indices = Set.new

    @search_index.each do |key, indices|
      if key.include?(query)
        matching_indices.merge(indices)
      end
    end

    matching_indices.map { |idx| @contacts[idx] }
  end

  def display_contacts
    if @contacts.empty?
      puts "\nNo contacts found."
      return
    end

    @contacts.each do |contact|
      display_contact(contact)
    end
  end

  private

  def display_contact(contact)
    puts "\n#{'-' * 40}"
    puts "ID:     #{contact['id']}"
    puts "Name:   #{contact['name']}"
    puts "Phone:  #{contact['phone']}"
    puts "Email:  #{contact['email']}"
    puts "Created: #{contact['created_at']}"
    puts "Updated: #{contact['updated_at']}" if contact['updated_at']
    puts "#{'-' * 40}"
  end

  # Rest of the private methods remain the same...
  def generate_id
    "cnt_#{Time.now.to_i}_#{rand(1000..9999)}"
  end

  def valid_phone?(phone)
    phone.strip.match?(/^\+?[\d\s-]{10,}$/)
  end

  def valid_email?(email)
    email.strip.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  def load_contacts
    if File.exist?(@file_path)
      @contacts = JSON.parse(File.read(@file_path))
    else
      @contacts = []
      save_contacts
    end
  rescue JSON::ParserError
    @contacts = []
    save_contacts
  end

  def save_contacts
    File.write(@file_path, JSON.pretty_generate(@contacts))
  end

  def build_search_index
    @search_index.clear
    @contacts.each_with_index do |contact, idx|
      add_to_search_index(contact, idx)
    end
  end

  def add_to_search_index(contact, idx)
    name = contact['name'].downcase
    (0...name.length).each do |i|
      (i...name.length).each do |j|
        substring = name[i..j]
        @search_index[substring] ||= Set.new
        @search_index[substring].add(idx)
      end
    end
  end
end

# Updated main interface
def display_menu
  puts "\nContact Manager"
  puts "1. Create New Contact"
  puts "2. Search Contacts"
  puts "3. Display All Contacts"
  puts "4. Update Contact"
  puts "5. Delete Contact"
  puts "6. Exit"
  print "\nEnter your choice (1-6): "
end

# New method: Handle update contact
def handle_update_contact(manager)
  print "\nEnter contact ID to update: "
  id = gets.chomp
  
  result = manager.update_contact(id)
  if result[:success]
    puts "\nSuccess: #{result[:message]}"
    display_contact(result[:contact])
  else
    puts "\nError: #{result[:message]}"
  end
end

# New method: Handle delete contact
def handle_delete_contact(manager)
  print "\nEnter contact ID to delete: "
  id = gets.chomp
  
  result = manager.delete_contact(id)
  if result[:success]
    puts "\nSuccess: #{result[:message]}"
  else
    puts "\nError: #{result[:message]}"
  end
end

# Existing handle methods remain the same
def handle_create_contact(manager)
  print "\nEnter name: "
  name = gets.chomp
  print "Enter phone number: "
  phone = gets.chomp
  print "Enter email: "
  email = gets.chomp

  result = manager.create_contact(name, phone, email)
  if result[:success]
    puts "\nSuccess: #{result[:message]}"
    display_contact(result[:contact])
  else
    puts "\nError: #{result[:message]}"
  end
end

def handle_search(manager)
  print "\nEnter search term: "
  query = gets.chomp
  results = manager.search(query)
  
  if results.empty?
    puts "\nNo matching contacts found."
  else
    puts "\nFound #{results.length} matching contacts:"
    results.each do |contact|
      display_contact(contact)
    end
  end
end

def display_contact(contact)
  puts "\n#{'-' * 40}"
  puts "ID:    #{contact['id']}"
  puts "Name:  #{contact['name']}"
  puts "Phone: #{contact['phone']}"
  puts "Email: #{contact['email']}"
  puts "#{'-' * 40}"
end

# Updated main program
manager = ContactManager.new

loop do
  display_menu
  choice = gets.chomp

  case choice
  when '1'
    handle_create_contact(manager)
  when '2'
    handle_search(manager)
  when '3'
    manager.display_contacts
  when '4'
    handle_update_contact(manager)
  when '5'
    handle_delete_contact(manager)
  when '6'
    puts "\nGoodbye!"
    break
  else
    puts "\nInvalid choice. Please try again."
  end
end