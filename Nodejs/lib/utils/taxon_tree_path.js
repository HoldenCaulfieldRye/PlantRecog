function find_path_to_all_nodes(){
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent : 1, _id : 0});
	for (var i =0; i< cursor.length();i++){
		var parent = tojson(cursor[i]["Parent"]);
		var path = find_path_from_node(parent);
		path = path.split(',');
		traverse_update_path(path);
	}
}

function traverse_update_path(path){
	for (var i in path){
		var node = path[0];
		path.splice(0,1);
		db.taxonomy.update({Parent : node }, {$set : {Path : path }} );
	}
}

function find_path_from_node(child){
	var data = db.taxonomy.findOne({Children : {$in : [ child ] }});
	if(data){
		var parent = find_path_from_node(data["Parent"]);
		return CHILD + ',' + parent;
	}
	else return CHILD;
}
