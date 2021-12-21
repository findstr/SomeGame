local E = require "E"

function E.roomlist_r(req)
	print("roomlist_r")
	return "roomlist_a", {list = {}}
end

function E.roomcreate_r(req)
	print("roomcreate_a")
	return "roomcreate_a", {}
end

