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
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	//for each leaf node traverse its path updating the count of elements below it
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_descendant_count(path, tag, prob);			
	}
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_bucket(path, threshold);			
	}
}

function traverse_update_descendant_count(path, tag, prob){
	//add condition to the following...i.e tag = X, prob = Y, synset_id's in path, or 1 synset at a time
	//ideally we'd do this once for all synsets and leave it globally defined....consider that!
	var count_by_synset = db.plants.group({ key: {Synset_ID:1}, reduce: function(curr,res){res.count++}, initial:{count:0} })
	var count = 0;
	for (var i in path){
		var node = path[i];
		count+= count_by_synset(node);
		db.buckets.update({Node:node}, {$inc:{Count:count}, Bucket:node});
	}
}

function traverse_update_bucket(path, threshold){
	var running_count = 0;
	var index = 0;
	while(running_count<threshold){
		for (var i in path){
			var node = path[i];
			var data = db.buckets.findOne({Node:node}, {Count:1 , _id:0});
			running_count+=data["Count"];
			if(running_count >= threshold){
				index = i;
				break;
			}
		}
	}
	if(index>0){
		bucket = path[index];
		for(index; index>=0; index--){
			db.buckets.update({Node:path[index]}, {Bucket:bucket});
		}
	}
}
