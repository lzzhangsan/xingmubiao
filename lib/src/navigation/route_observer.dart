import 'package:flutter/material.dart';

/// 全局 RouteObserver 单例，用于页面可见性/RouteAware 回调
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
