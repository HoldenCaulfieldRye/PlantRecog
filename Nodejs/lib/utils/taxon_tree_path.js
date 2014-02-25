function find_path_to_all_nodes(){
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent : 1, _id : 0});
	for (var i =0; i< cursor.length();i++){
		var parent = tojson(cursor[i]["Parent"]);
		var path = find_path_from_node(eval(parent));
		path = path.split(',');
		traverse_update_path(path);
	}
}

function traverse_update_path(path){
	for (var i in path){
		var node = path[0];
		path.splice(0,1);
		db.taxonomy.update({Parent:node}, {$set:{Path:path}});
	}
}

function find_path_from_node(child){
	var data = db.taxonomy.findOne({Children : {$in : [ child ] }});
	if(data){
		var parent = find_path_from_node(data["Parent"]);
		return child + ',' + parent;
	}
	else return child;
}


function bucketing(threshold, tag, prob){
	//find leaf nodes (easiest to find)
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent : 1, _id : 0});
	//for each leaf node traverse its path updating the count of elements below it
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		traverse_update_descendants_count((parent + path), tag, prob);			
	}
}

function traverse_update_descendants_count(path, tag, prob, threshold){
	//add condition to the following...i.e tag = X, prob = Y
	var count_by_synset = db.plants.group({ key: {Synset_ID:1}, reduce: function(curr,res){res.count++}, initial:{count:0} })
	var count = 0;
	var path_index = 0;
	for (var i in path){
		var node = path[i];
		//count starts at zero at leaf node and increases for each ancestor
		count+= count_by_synset(node);
		if(count >=threshold){
			path_index = i;
			}
		//better to add to new table, but what other info do we need to include??
		db.buckets.update({Node:node}, {$inc : { Count : count}});
	}
	var bucket = path[path_index];
	for(path_index; path_index>=0; path_index--){
		db.buckets.update({Node:path[path_index]}, {$set : { Bucket : bucket}});
	}
}
