import 'package:simple_cluster/src/common.dart';

///Density-based spatial clustering of applications with noise (DBSCAN)
class DBSCAN<T, E> {
  ///Complete list of points (in vector form)
  late List<T> dataset;

  ///Result clusters
  List<List<int>> _cluster = [];

  ///Index of points considered as noise
  List<int> _noise = [];

  ///Cluster label, if prefer sklearn structure of output
  List<int>? _label;

  ///Threshold distance for two points to be considered as neighbor
  final double epsilon;

  ///Minimum points in neighborhood to be considered as a cluster
  final int minPoints;

  final double Function(E, E) distanceMeasure;

  final E Function(T) getPoint;

  ///Cluster label
  int? _currentLabel;

  DBSCAN({
    this.epsilon = 1,
    this.minPoints = 2,
    required this.getPoint,
    required this.distanceMeasure
  });

  ///Index of points considered as noise
  List<int> get noise {
    return _noise;
  }

  ///Result clusters
  List<List<int>> get cluster {
    return _cluster;
  }

  ///Cluster label for each points, if prefers sklearn's output structure.
  ///
  ///-1 means noise (doesn't belong in any cluster)
  List<int>? get label {
    return _label;
  }

  ///Run clustering process, add configs in constructor
  List<List<int>> run(List<T> dataset) {
    if (dataset == null) {
      throw new Exception("Dataset must not be null");
    }

    //save dataset to class' variable
    this.dataset = dataset;

    //initial variables
    _cluster = [];
    _currentLabel = -1;
    _label = List.generate(dataset.length, (_) => -1);

    for (int i = 0; i < dataset.length; i++) {
      //skip labeled points
      if (_label![i] != -1) continue;

      //neighbor indexes
      List<int> neighbors = _rangeQuery(getPoint(dataset[i]));

      if (neighbors.length < minPoints) {
        _noise.add(i);
      } else {
        //add new cluster
        List<int> newCluster = [];
        _currentLabel = _currentLabel! + 1;
        _cluster.add(newCluster);
        _expandCluster(i, neighbors, newCluster);
      }
    }

    return _cluster;
  }

  ///Expand cluster by checking neighbor's neighbor.
  ///
  ///Mutates parameter `neighbors` and `cluster`.
  void _expandCluster(int pointIndex, List<int> neighbors, List<int> cluster) {
    _addToCluster(pointIndex, _currentLabel!);

    for (int i = 0; i < neighbors.length; i++) {
      //Change Noise to border point
      if (_noise.contains(neighbors[i])) {
        _noise.remove(neighbors[i]);
        _addToCluster(neighbors[i], _currentLabel!);
      }

      //skip labeled points
      if (_label![neighbors[i]] != -1) continue;

      //add point to cluster
      _addToCluster(neighbors[i], _currentLabel!);

      //expand neighborhood
      List<int> expandedNeighbors = _rangeQuery(getPoint(dataset[neighbors[i]]));

      if (expandedNeighbors.length >= minPoints) {
        neighbors = _joinIndexList(neighbors, expandedNeighbors);
      }
    }
  }

  ///Add to cluster and set label to point
  void _addToCluster(int pointIndex, int clusterLabel) {
    _cluster[clusterLabel].add(pointIndex);
    _label![pointIndex] = clusterLabel;
  }

  ///Return all point's index within p's eps-neighborhood (including p)
  List<int> _rangeQuery(E p) {
    List<int> neighbors = [];
    for (int i = 0; i < dataset.length; i++) {
      if (distanceMeasure(p, getPoint(dataset[i])) <= epsilon) {
        neighbors.add(i);
      }
    }

    return neighbors;
  }

  List<int> _joinIndexList(List<int> list1, List<int> list2) {
    List<int> newList = [...list1];

    for (int i = 0; i < list2.length; i++) {
      if (!newList.contains(list2[i])) {
        newList.add(list2[i]);
      }
    }

    return newList;
  }
}
