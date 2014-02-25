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
	initialise_count_agg(tag,prob);
	//find leaf nodes (easiest to find)
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	//for each leaf node traverse its path updating the count of elements below it
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_descendant_count(path);			
	}
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_bucket(path, threshold);			
	}
	//now return result
	var res = db.plants.find({},{Image:1, Species:1, _id:0});
	//possible add constraint:
	//	where not count<threshold, bucket == synset_id....this suggests the item is unclassifiable
	// then remove all excluded images
	//need to fiz comparing bucket and synset cols
	var res = db.plants.find({ Exclude:false, Count : {$gte : threshold}, Bucket : {$ne : Synset_ID } } , {Image:1, Species:1, _id:0});	
	return res;	
}

var count_by_synset;

function initialise_count_agg(tag, prob){
	count_by_synset = new Object();
	var res = db.plants.aggregate(
		{ $match : {Component_Tag : tag , Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
		{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
	);
	for (var i = 0 ; i< res.result.length; i++ ){
		count_by_synset[res.result[i]._id] = res.result[i].count;
	}
}

function traverse_update_descendant_count(path){
	var count = 0;
	for (var i in path){
		var node = path[i];
		count += count_by_synset[node];
		//defualt bucket to itself. we won't know until all nodes have been updated with their count if they need bucketed into an ancestor node
		//db.buckets.update({Node:node}, {$inc:{Count:count}, Bucket:node});
		//needs to be a findAndModify query on the plants db....?
		db.plants.findAndModify({
			query  : { Synset_ID : node, Exclude : false}, 
			update : { $inc : {Count : count}, Bucket : node}
		});
		db.plants.findAndModify({
			query  : { Synset_ID : node, Exclude : true}, 
			update : { Count : 0, Bucket : node}
	}
}

function traverse_update_bucket(path, threshold){
	var running_count = 0;
	var index = 0;
	var bucket;
	while(running_count<threshold){
		for (var i in path){
			bucket = path[i];
			var data = db.buckets.findOne({Node:bucket}, {Count:1 , _id:0});
			running_count += data.Count;
			if(running_count >= threshold){
				index = i;
				break;
			}
		}
	}
	if(index>0){
		for(index; index>=0; index--){
			//db.buckets.update({Node:path[index]}, {Bucket:bucket});
			//var ex = db.taxonomy.findOne({Parent : bucket}, {Exclude:1, _id:0});
			// if the proposed bucket is to be excluded then don't update it.
			var ex = db.plants.findOne({Synset_ID : bucket}, {Exclude:1, _id:0});
			if(!ex.Exclude){
				//db.buckets.findAndModify({
				db.plants.findAndModify({
					//query  : { Node   : path[index] }, 
					query  : { Synset_ID : path[index] }, 
					update : { Bucket : bucket }
				});
			}
		}
	}
}
