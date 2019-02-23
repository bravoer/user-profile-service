###
# Vocabularies
###

MU_SESSION = RDF::Vocabulary.new(MU.to_uri.to_s + 'session/')
MU_AUTH = RDF::Vocabulary.new(MU.to_uri.to_s + 'authorization/')
MUSIC = RDF::Vocabulary.new(MU_EXT.to_uri.to_s + 'music/')
BRAV = RDF::Vocabulary.new(MU_EXT.to_uri.to_s + 'bravoer/')

###
# GET /userprofile
#
# Returns 200 containing the userprofile
#         400 if session header is missing
###
get '/userprofile/?' do
  content_type 'application/vnd.api+json'

  ###
  # Validate headers
  ###
  session_uri = session_id_header(request)
  error('Session header is missing') if session_uri.nil?

  ###
  # Get userprofile
  ###
  result = select_user_profile_by_session(session_uri)
  error("No user found for session #{session_uri}") if result.empty?

  ###
  # Assemble profile
  ###
  profile = { authGroups: [] }
  result.each do |solution|
    profile[:name] = solution[:userName]
    profile[:instrument] = solution[:instrument] if solution[:instrument]
    profile[:musician] = solution[:musicianUuid] if solution[:musicianUuid]
    profile[:authGroups] << solution[:groupName] if solution[:groupName]
  end

  status 200
  profile.to_json
end



helpers do

  def select_user_profile_by_session(session)
    query = " SELECT ?userName ?instrument ?groupName ?musicianUuid FROM <#{graph}> WHERE {"
    query += "  <#{session}> <#{MU_SESSION.account}>/^<#{RDF::Vocab::FOAF.account}> ?user ."
    query += "  ?user <#{RDF::Vocab::FOAF.name}> ?userName ."
    query += "  "
    query += "  OPTIONAL {"
    query += "    ?user <#{MU_AUTH.belongsToActorGroup}> ?group ."
    query += "    ?group <#{RDF::Vocab::FOAF.name}> ?groupName ."
    query += "  }"
    query += "  "
    query += "  OPTIONAL {"
    query += "    ?musician <#{BRAV.hasUser}> ?user ;"
    query += "              <#{MU.uuid}> ?musicianUuid ;"
    query += "              <#{MUSIC.instrument}> ?instrument ."
    query += "  }"
    query += "}"
    query(query)
  end

end
